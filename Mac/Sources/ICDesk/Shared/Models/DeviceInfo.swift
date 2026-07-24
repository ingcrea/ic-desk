import Foundation

/// `DeviceInfo` representa la información estática y básica de un dispositivo (Mac o iOS).
/// Se utiliza para identificar el dispositivo dentro del sistema de IC Desk.
public struct DeviceInfo: Codable {
    /// Identificador único del dispositivo (UUID).
    public let id: String
    /// Nombre asignado al dispositivo por el usuario.
    public let name: String
    /// Sistema operativo del dispositivo (ej. macOS 14.0 o iOS 17.0).
    public let osVersion: String
    /// Modelo del hardware del dispositivo.
    public let model: String

    /// Inicializador principal de la estructura `DeviceInfo`.
    /// - Parameters:
    ///   - id: Identificador único del dispositivo.
    ///   - name: Nombre del dispositivo.
    ///   - osVersion: Versión del sistema operativo.
    ///   - model: Modelo del hardware.
    public init(id: String, name: String, osVersion: String, model: String) {
        self.id = id
        self.name = name
        self.osVersion = osVersion
        self.model = model
    }
}

/// `DeviceResponse` encapsula la respuesta estandarizada para operaciones relacionadas con dispositivos.
/// Sigue el formato { "success": true, "data": { ... } } o { "success": false, "error": { ... } }.
public struct DeviceResponse: Codable {
    /// Indica si la operación fue exitosa.
    public let success: Bool
    /// Los datos devueltos en caso de éxito.
    public let data: DeviceInfo?
    /// Detalles del error en caso de fallo.
    public let error: ErrorDetail?
}

/// `ErrorDetail` contiene la información estructurada de un error.
public struct ErrorDetail: Codable {
    /// Código específico del error.
    public let code: String
    /// Mensaje descriptivo del error en texto plano.
    public let message: String
}
