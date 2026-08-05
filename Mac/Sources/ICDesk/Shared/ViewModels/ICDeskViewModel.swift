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
    
    /// Inicia el proceso de conexión al servidor IC Desk.
    public func connect() {
        Task {
            await webSocketClient.connect(withPIN: self.supportPIN)
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
