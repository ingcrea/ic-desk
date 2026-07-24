import Foundation

/// `CommandType` define los posibles tipos de comandos que pueden recibirse desde el servidor remoto.
public enum CommandType: String, Codable {
    /// Comando para iniciar la transmisión de pantalla.
    case startScreenShare
    /// Comando para detener la transmisión de pantalla.
    case stopScreenShare
    /// Comando para solicitar métricas del sistema actualizadas.
    case requestMetrics
    /// Comando para ejecutar una simulación de evento de entrada (mouse/teclado).
    case injectInput
}

/// `RemoteCommand` representa una instrucción enviada desde el servidor central de IC Desk hacia el cliente.
public struct RemoteCommand: Codable {
    /// Identificador único del comando para seguimiento y acuses de recibo.
    public let commandId: String
    /// El tipo de comando a ejecutar.
    public let type: CommandType
    /// Carga útil adicional en formato JSON genérico (diccionario codificado) si el comando requiere parámetros.
    public let payload: [String: String]?

    /// Crea un nuevo comando remoto.
    /// - Parameters:
    ///   - commandId: ID del comando.
    ///   - type: Tipo de comando.
    ///   - payload: Parámetros opcionales.
    public init(commandId: String, type: CommandType, payload: [String: String]? = nil) {
        self.commandId = commandId
        self.type = type
        self.payload = payload
    }
}
