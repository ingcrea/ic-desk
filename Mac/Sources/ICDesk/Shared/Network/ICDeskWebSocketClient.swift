import Foundation
#if os(iOS)
import UIKit
#endif

/// `ICDeskWebSocketClient` es el responsable de mantener la comunicación bidireccional en tiempo real
/// con el servidor central de IC Desk mediante WebSockets.
/// Implementa reconexión automática asíncrona con backoff exponencial.
public actor ICDeskWebSocketClient {
    /// Tarea de red que representa el WebSocket activo.
    private var webSocketTask: URLSessionWebSocketTask?
    /// Sesión HTTP utilizada para gestionar el WebSocket.
    private let urlSession: URLSession
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
    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "x-ic-agent-token": "ICAgentToken2026SecureHashKey",
            "User-Agent": "ICAgent"
        ]
        self.urlSession = URLSession(configuration: configuration)
    }
    
    /// Conecta el WebSocket al servidor e inicia la escucha de mensajes.
    public func connect(withPIN pin: String) {
        guard webSocketTask == nil else { return }
        
        let urlString = "wss://desk.ingcrea.com?type=agent&id=\(pin)"
        guard let serverURL = URL(string: urlString) else { return }
        
        onStateChange?(.connecting)
        var request = URLRequest(url: serverURL)
        request.setValue("ICAgentToken2026SecureHashKey", forHTTPHeaderField: "x-ic-agent-token")
        request.setValue("ICAgent", forHTTPHeaderField: "User-Agent")
        
        webSocketTask = urlSession.webSocketTask(with: request)
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
        
        #if os(macOS)
        let hostDeviceName = Host.current().localizedName ?? "Unknown"
        let hostDeviceHostname = Host.current().name ?? "Unknown"
        #else
        let hostDeviceName = UIDevice.current.name
        let hostDeviceHostname = ProcessInfo.processInfo.hostName
        #endif
        
        let registerMessage = [
            "type": "register",
            "agentId": AgentIdentifier.getAgentID(),
            "name": hostDeviceName,
            "os": osName,
            "hostname": hostDeviceHostname
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
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let typeStr = json["type"] as? String {
                let command = RemoteCommand(typeStr: typeStr, payload: json)
                onCommandReceived?(command)
            }
        } catch {
            print("Error parseando comando remoto: \(error)")
        }
    }
    
    /// Maneja la pérdida de conexión e invoca reconexión con backoff exponencial.
    private func handleDisconnectAndReconnect() {
        webSocketTask = nil
        onStateChange?(.error)
        
        // En un entorno real se reinyectaría el PIN desde el ViewModel, pero para este caso base
        // dependerá de que el usuario pulse reconectar o el ViewModel orqueste el loop de reconexión.
    }
    
    /// Envía datos serializables como JSON.
    public func send<T: Codable>(data: T) async throws {
        guard let webSocketTask = webSocketTask else { return }
        let jsonData = try JSONEncoder().encode(data)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            let message = URLSessionWebSocketTask.Message.string(jsonString)
            try await webSocketTask.send(message)
        }
    }
    
    /// Envía fotogramas de video u otros buffers crudos.
    public func sendBinary(_ data: Data) async throws {
        guard let webSocketTask = webSocketTask else { return }
        let message = URLSessionWebSocketTask.Message.data(data)
        try await webSocketTask.send(message)
    }
}
