import Foundation

/// `ICDeskWebSocketClient` es el responsable de mantener la comunicación bidireccional en tiempo real
/// con el servidor central de IC Desk mediante WebSockets.
/// Implementa reconexión automática asíncrona con backoff exponencial.
public actor ICDeskWebSocketClient {
    /// Tarea de red que representa el WebSocket activo.
    private var webSocketTask: URLSessionWebSocketTask?
    /// Sesión HTTP utilizada para gestionar el WebSocket.
    private let urlSession: URLSession
    /// URL del servidor de IC Desk (ej. soporte.sercommx.com:6001).
    private let serverURL: URL
    /// Control del tiempo de espera para el backoff exponencial en reconexiones.
    private var reconnectDelay: TimeInterval = 1.0
    /// Límite máximo de espera entre intentos de reconexión (30 segundos).
    private let maxReconnectDelay: TimeInterval = 30.0
    
    /// Closure que notifica cambios de estado de la conexión.
    public var onStateChange: ((SessionState) -> Void)?
    /// Closure que notifica la recepción de un comando remoto.
    public var onCommandReceived: ((RemoteCommand) -> Void)?
    
    public func setOnStateChange(_ callback: @escaping (SessionState) -> Void) {
        self.onStateChange = callback
    }
    
    public func setOnCommandReceived(_ callback: @escaping (RemoteCommand) -> Void) {
        self.onCommandReceived = callback
    }
    
    /// Inicializa un nuevo cliente WebSocket para IC Desk.
    /// - Parameter urlString: La URL base del servidor.
    public init(urlString: String = "wss://soporte.sercommx.com:6001/ws") {
        self.serverURL = URL(string: urlString)!
        self.urlSession = URLSession(configuration: .default)
    }
    
    /// Conecta el WebSocket al servidor e inicia la escucha de mensajes.
    public func connect() {
        guard webSocketTask == nil else { return }
        
        onStateChange?(.connecting)
        webSocketTask = urlSession.webSocketTask(with: serverURL)
        webSocketTask?.resume()
        
        onStateChange?(.connected)
        reconnectDelay = 1.0 // Reset del delay de reconexión tras éxito
        
        Task {
            await registerAgent()
            await listenForMessages()
        }
        
        startHeartbeat()
    }
    
    /// Tarea de heartbeat.
    private var heartbeatTask: Task<Void, Never>?
    
    /// Inicia el latido periódico para mantener viva la sesión.
    private func startHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000) // 15 segundos
                guard webSocketTask != nil else { break }
                let pingMessage = ["type": "heartbeat", "timestamp": "\(Date().timeIntervalSince1970)"]
                try? await send(data: pingMessage)
            }
        }
    }
    
    /// Envía el mensaje inicial de registro al servidor.
    private func registerAgent() async {
        let osName: String
        #if os(macOS)
        osName = "macOS"
        #elseif os(iOS)
        osName = "iOS"
        #else
        osName = "Unknown"
        #endif
        
        let registerMessage = [
            "type": "register",
            "agentId": AgentIdentifier.getAgentID(),
            "name": Host.current().localizedName ?? "Unknown",
            "os": osName,
            "hostname": Host.current().name ?? "Unknown"
        ]
        
        do {
            try await send(data: registerMessage)
            print("Registro de agente enviado con éxito.")
        } catch {
            print("Error al enviar registro de agente: \(error)")
        }
    }
    
    /// Cierra de manera limpia la conexión activa.
    public func disconnect() {
        heartbeatTask?.cancel()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        onStateChange?(.disconnected)
    }
    
    /// Bucle infinito que escucha mensajes entrantes del WebSocket.
    /// Si ocurre un error, inicia la secuencia de reconexión automática.
    private func listenForMessages() async {
        guard let task = webSocketTask else { return }
        
        do {
            let message = try await task.receive()
            switch message {
            case .string(let text):
                handleIncomingMessage(text: text)
            case .data(let data):
                print("Datos binarios recibidos: \(data.count) bytes")
            @unknown default:
                break
            }
            // Continuar escuchando recursivamente
            if webSocketTask != nil {
                await listenForMessages()
            }
        } catch {
            print("Error al recibir mensaje: \(error.localizedDescription)")
            handleDisconnectAndReconnect()
        }
    }
    
    /// Procesa un mensaje de texto entrante y lo decodifica como `RemoteCommand`.
    /// - Parameter text: El string JSON recibido.
    private func handleIncomingMessage(text: String) {
        guard let data = text.data(using: .utf8) else { return }
        do {
            let command = try JSONDecoder().decode(RemoteCommand.self, from: data)
            onCommandReceived?(command)
        } catch {
            print("Error decodificando comando remoto: \(error)")
        }
    }
    
    /// Maneja la pérdida de conexión e invoca reconexión con backoff exponencial.
    private func handleDisconnectAndReconnect() {
        webSocketTask = nil
        onStateChange?(.error)
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(reconnectDelay * 1_000_000_000))
            reconnectDelay = min(reconnectDelay * 2, maxReconnectDelay)
            print("Intentando reconectar en \(reconnectDelay) segundos...")
            connect()
        }
    }
    
    /// Envía un mensaje JSON estructurado al servidor a través del WebSocket.
    /// - Parameter data: Objeto codificable (ej. MetricsResponse o DeviceResponse).
    public func send<T: Codable>(data: T) async throws {
        let jsonData = try JSONEncoder().encode(data)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        try await webSocketTask?.send(message)
    }
}
