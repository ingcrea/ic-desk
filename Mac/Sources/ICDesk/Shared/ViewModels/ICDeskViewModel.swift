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
            
            #if os(macOS)
            screenManager.onFrameCaptured = { [weak self] frameData in
                Task {
                    try? await self?.webSocketClient.sendBinary(frameData)
                }
            }
            #endif
        }
    }
    
    private var isPolling = false
    
    /// Inicia el proceso de conexión híbrida (Registro HTTP -> Poll -> WebSocket a demanda).
    public func connect() {
        guard !isPolling else { return }
        isPolling = true
        
        Task {
            while isPolling {
                await MainActor.run { self.sessionState = .connecting }
                
                let registered = await registerAgent()
                if registered {
                    await MainActor.run { self.sessionState = .connected }
                    
                    // Loop de polling
                    while isPolling {
                        let ok = await pollCommands()
                        if !ok { break } // Si falla gravemente, salimos para reconectar
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 segundo
                    }
                } else {
                    // Falló registro, esperar y reintentar
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
                if let jsonString = String(data: data, encoding: .utf8) {
                    if jsonString.contains("\"command\":null") || jsonString.isEmpty {
                        return true
                    }
                    
                    if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let cmdText = dict["text"] as? String {
                            await handlePolledCommand(cmdText)
                        }
                    }
                }
                return true
            }
        } catch {
            print("Error en polling: \(error)")
        }
        return false
    }
    
    private func handlePolledCommand(_ cmdText: String) async {
        if cmdText.hasPrefix("__RELAY_START__") {
            if sessionState != .screenSharing {
                await MainActor.run { self.sessionState = .screenSharing }
                // Iniciar WebSocket para streaming
                await webSocketClient.connect(withPIN: self.supportPIN)
            }
        } else if cmdText.hasPrefix("__RELAY_STOP__") {
            await MainActor.run { self.sessionState = .connected }
            await webSocketClient.disconnect()
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
            #if os(macOS)
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
            #if os(macOS)
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
