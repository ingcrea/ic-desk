import Foundation
import Combine
#if os(macOS)
import CoreGraphics
#endif

/// `ICDeskViewModel` es el modelo de vista principal (ViewModel) de la aplicación.
/// Mantiene el estado reactivo de la UI, orquesta las conexiones de red y
/// procesa los comandos que ingresan.
/// Está aislado en el `@MainActor` para garantizar que toda actualización
/// de la interfaz de usuario se haga de manera segura en el hilo principal.
@MainActor
public class ICDeskViewModel: ObservableObject {
    
    /// Estado actual de la conexión de la sesión. Expuesto a SwiftUI.
    @Published public var sessionState: SessionState = .disconnected
    
    /// Última información de métricas obtenidas.
    @Published public var currentMetrics: SystemMetrics?
    
    /// Cliente WebSocket encapsulado en el ViewModel.
    private let webSocketClient: ICDeskWebSocketClient
    
    #if os(macOS)
    private let screenManager = ScreenCaptureManager()
    private let inputManager = InputControlManager()
    #elseif os(iOS)
    private let screenManager = ReplayKitBroadcastManager()
    #endif
    
    /// ID de soporte persistente generado por hardware
    @Published public var supportPIN: String = ""
    
    /// Inicializa el ViewModel principal de IC Desk.
    public init() {
        self.webSocketClient = ICDeskWebSocketClient()
        self.supportPIN = AgentIdentifier.getAgentID()
        setupBindings()
        
        // Iniciar el chequeo silencioso de actualizaciones OTA
        OTAUpdater.shared.start()
        
        // Iniciar recolección periódica de métricas
        startMetricsLoop()
    }
    
    private func startMetricsLoop() {
        Task {
            while true {
                #if os(macOS)
                self.currentMetrics = SystemDiagnostics().fetchMetrics()
                #elseif os(iOS)
                self.currentMetrics = iOSDiagnostics().fetchMetrics()
                #endif
                try? await Task.sleep(nanoseconds: 2_000_000_000) // Cada 2 segundos
            }
        }
    }
    
    /// Configura los callbacks del cliente WebSocket para reaccionar a cambios
    /// de estado y recepción de comandos de forma asíncrona.
    private func setupBindings() {
        Task {
            await webSocketClient.setOnStateChange { [weak self] state in
                Task { @MainActor in
                    self?.sessionState = state
                }
            }
            
            await webSocketClient.setOnCommandReceived { [weak self] command in
                Task { @MainActor in
                    self?.handleCommand(command)
                }
            }
            
            #if os(macOS) || os(iOS)
            screenManager.onFrameCaptured = { [weak self] frameData in
                Task {
                    try? await self?.webSocketClient.sendBinary(frameData)
                }
            }
            #endif
        }
    }
    
    private var isPolling = false
    
    /// Inicia el proceso de conexión híbrida:
    /// 1) Registro HTTP -> Poll de comandos
    /// 2) WebSocket Relay (siempre conectado para video)
    public func connect() {
        guard !isPolling else { return }
        isPolling = true
        
        // Conectar siempre al relay WS para que el panel tenga video disponible
        Task {
            await webSocketClient.connect(withPIN: self.supportPIN)
        }
        
        Task {
            while isPolling {
                await MainActor.run { self.sessionState = .connecting }
                
                let registered = await registerAgent()
                if registered {
                    await MainActor.run { self.sessionState = .connected }
                    
                    // Loop de polling — paridad con Windows IcDesk.cs
                    while isPolling {
                        let ok = await pollCommands()
                        if !ok { break }
                        try? await Task.sleep(nanoseconds: 500_000_000) // 500ms — responde antes del timeout 504
                    }
                } else {
                    // Falló registro, esperar 5s y reintentar
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                }
            }
        }
    }
    
    private func registerAgent() async -> Bool {
        let urlString = "https://desk.ingcrea.com/soporte/register"
        guard let url = URL(string: urlString) else { return false }
        
        let hostName = ProcessInfo.processInfo.hostName
        let payload: [String: Any] = [
            "id": self.supportPIN,
            "hostname": hostName,
            "isAdmin": false,
            "health": NSNull()
        ]
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("ICAgentToken2026SecureHashKey", forHTTPHeaderField: "x-ic-agent-token")
        
        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, res) = try await URLSession.shared.data(for: req)
            if let httpRes = res as? HTTPURLResponse, httpRes.statusCode == 200 {
                return true
            }
        } catch {
            print("Error registrando agente HTTP: \(error)")
        }
        return false
    }
    
    private func pollCommands() async -> Bool {
        let ts = Int(Date().timeIntervalSince1970 * 1000)
        let urlString = "https://desk.ingcrea.com/soporte/poll?id=\(self.supportPIN)&_t=\(ts)"
        guard let url = URL(string: urlString) else { return false }
        
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 4.0
        req.setValue("ICAgentToken2026SecureHashKey", forHTTPHeaderField: "x-ic-agent-token")
        
        do {
            let (data, res) = try await URLSession.shared.data(for: req)
            if let httpRes = res as? HTTPURLResponse, httpRes.statusCode == 200 {
                guard let jsonString = String(data: data, encoding: .utf8),
                      !jsonString.isEmpty,
                      !jsonString.contains("\"command\":null") else {
                    return true // Sin comandos pendientes, todo OK
                }
                
                if let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dict = root["command"] as? [String: Any] {
                    let cmdId   = dict["id"]   as? String ?? ""
                    let cmdText = dict["text"] as? String ?? ""
                    if !cmdId.isEmpty && !cmdText.isEmpty {
                        let output = await handlePolledCommand(cmdText: cmdText)
                        // Responder al servidor para evitar el 504
                        await sendResponse(cmdId: cmdId, output: output)
                    }
                }
                return true
            }
        } catch {
            print("[IC Desk] Error en polling: \(error)")
        }
        return false
    }
    
    /// Envía la respuesta de un comando al servidor — equivale a SendResponse() de C#
    private func sendResponse(cmdId: String, output: String) async {
        guard let url = URL(string: "https://desk.ingcrea.com/soporte/response") else { return }
        
        let safeOutput = output
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        
        let payload: [String: Any] = [
            "id":    self.supportPIN,
            "cmdId": cmdId,
            "output": safeOutput
        ]
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("ICAgentToken2026SecureHashKey", forHTTPHeaderField: "x-ic-agent-token")
        
        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            _ = try await URLSession.shared.data(for: req)
        } catch {
            print("[IC Desk] Error enviando respuesta de comando: \(error)")
        }
    }
    
    /// Procesa el texto del comando y retorna la salida como String (para enviar al servidor).
    private func handlePolledCommand(cmdText: String) async -> String {
        if cmdText.hasPrefix("__RELAY_START__") {
            await MainActor.run { self.sessionState = .screenSharing }
            
            #if os(macOS) || os(iOS)
            do {
                try await screenManager.startCapture()
            } catch {
                print("Error iniciando captura de pantalla: \(error)")
            }
            #endif
            
            // El relay WS ya está conectado desde connect(), solo confirmar
            return "RELAY_ACTIVE"
        } else if cmdText.hasPrefix("__RELAY_STOP__") {
            await MainActor.run { self.sessionState = .connected }
            
            #if os(macOS) || os(iOS)
            do {
                try await screenManager.stopCapture()
            } catch {
                print("Error deteniendo captura de pantalla: \(error)")
            }
            #endif
            
            return "RELAY_STOPPED"
        } else if cmdText.hasPrefix("__ELEVATE__") {
            return "ELEVATION_NOT_SUPPORTED_IOS"
        } else {
            // Comando de texto genérico — en iOS no se puede ejecutar shell
            return "COMMAND_NOT_SUPPORTED_ON_THIS_PLATFORM"
        }
    }
    
    /// Finaliza y cierra la conexión al servidor.
    public func disconnect() {
        Task {
            await webSocketClient.disconnect()
        }
    }
    
    private func handleCommand(_ command: RemoteCommand) {
        print("Comando recibido: \(command.type)")
        switch command.type {
        case "requestMetrics":
            // TODO: Recolectar métricas usando diagnósticos nativos (SystemDiagnostics/iOSDiagnostics) y enviar de vuelta
            break
        case "start_stream":
            sessionState = .screenSharing
            #if os(macOS) || os(iOS)
            Task {
                do {
                    try await screenManager.startCapture()
                } catch {
                    print("Error iniciando captura de pantalla: \(error)")
                }
            }
            #endif
        case "stop_stream":
            sessionState = .connected
            #if os(macOS) || os(iOS)
            Task {
                do {
                    try await screenManager.stopCapture()
                } catch {
                    print("Error deteniendo captura de pantalla: \(error)")
                }
            }
            #endif
        case "mouse_move", "mouse_click", "mouse_scroll", "key_press":
            #if os(macOS)
            if let payload = command.payload {
                let action = command.type
                switch action {
                case "mouse_move":
                    if let x = payload["x"] as? Double, let y = payload["y"] as? Double {
                        inputManager.moveMouse(to: CGPoint(x: x, y: y))
                    }
                case "mouse_click":
                    if let button = payload["button"] as? String {
                        if button == "left" { inputManager.simulateLeftClick() }
                        else if button == "right" { inputManager.simulateRightClick() }
                    }
                case "key_press":
                    if let text = payload["text"] as? String {
                        inputManager.typeText(text)
                    }
                default: break
                }
            }
            #endif
            break
        default:
            print("Comando desconocido o no soportado: \(command.type)")
        }
    }
}
