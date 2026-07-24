import Foundation

/// `SessionState` define los posibles estados de la conexión de la aplicación IC Desk con el servidor.
public enum SessionState: String, Codable, Equatable {
    /// El cliente está completamente desconectado del servidor.
    case disconnected
    /// El cliente está intentando establecer una conexión.
    case connecting
    /// El cliente se ha conectado y autenticado exitosamente.
    case connected
    /// El cliente está compartiendo activamente su pantalla.
    case screenSharing
    /// Ha ocurrido un error en la conexión y se intentará reconectar.
    case error
}
