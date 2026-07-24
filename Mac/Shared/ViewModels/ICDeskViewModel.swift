import Foundation
import Combine

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
    
    /// Inicializa el ViewModel principal de IC Desk.
    public init() {
        self.webSocketClient = ICDeskWebSocketClient()
        setupBindings()
    }
    
    /// Configura los callbacks del cliente WebSocket para reaccionar a cambios
    /// de estado y recepción de comandos de forma asíncrona.
    private func setupBindings() {
        Task {
            await webSocketClient.onStateChange = { [weak self] state in
                Task { @MainActor in
                    self?.sessionState = state
                }
            }
            
            await webSocketClient.onCommandReceived = { [weak self] command in
                Task { @MainActor in
                    self?.handleCommand(command)
                }
            }
        }
    }
    
    /// Inicia el proceso de conexión al servidor IC Desk.
    public func connect() {
        Task {
            await webSocketClient.connect()
        }
    }
    
    /// Finaliza y cierra la conexión al servidor.
    public func disconnect() {
        Task {
            await webSocketClient.disconnect()
        }
    }
    
    /// Procesa un `RemoteCommand` recibido del servidor remoto.
    /// - Parameter command: El comando a ejecutar en el cliente.
    private func handleCommand(_ command: RemoteCommand) {
        print("Comando recibido: \(command.type)")
        switch command.type {
        case .requestMetrics:
            // TODO: Recolectar métricas usando diagnósticos nativos (SystemDiagnostics/iOSDiagnostics) y enviar de vuelta
            break
        case .startScreenShare:
            sessionState = .screenSharing
            // TODO: Iniciar captura nativa (ScreenCaptureManager/ReplayKit)
        case .stopScreenShare:
            sessionState = .connected
            // TODO: Detener captura
        case .injectInput:
            // TODO: Manejar eventos de teclado y ratón
            break
        }
    }
}
