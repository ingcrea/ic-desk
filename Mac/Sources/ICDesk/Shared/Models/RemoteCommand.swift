import Foundation

/// `RemoteCommand` representa una instrucción enviada desde el servidor central de IC Desk hacia el cliente.
public struct RemoteCommand {
    /// El tipo de comando a ejecutar.
    public let type: String
    /// Carga útil adicional en formato JSON genérico (diccionario).
    public let payload: [String: Any]?

    /// Crea un nuevo comando remoto.
    /// - Parameters:
    ///   - typeStr: Tipo de comando (ej. "mouse_move", "start_stream").
    ///   - payload: Parámetros opcionales.
    public init(typeStr: String, payload: [String: Any]? = nil) {
        self.type = typeStr
        self.payload = payload
    }
}
