import Foundation

/// `SystemMetrics` encapsula las métricas de rendimiento y estado del sistema en tiempo real.
/// Se usa para reportar el estado de la batería, memoria RAM, CPU y almacenamiento en IC Desk.
public struct SystemMetrics: Codable {
    /// Nivel de batería actual (0.0 a 1.0). Si es nil, el dispositivo no tiene batería o no se pudo leer.
    public let batteryLevel: Double?
    /// Uso actual del CPU en porcentaje (0.0 a 100.0).
    public let cpuUsage: Double
    /// Memoria RAM total disponible en el sistema en bytes.
    public let totalRAM: UInt64
    /// Memoria RAM actualmente en uso en bytes.
    public let usedRAM: UInt64
    /// Espacio de almacenamiento total en disco en bytes.
    public let totalDiskSpace: UInt64
    /// Espacio de almacenamiento disponible en disco en bytes.
    public let freeDiskSpace: UInt64

    /// Inicializa una nueva instancia de `SystemMetrics` con los datos de telemetría recopilados.
    /// - Parameters:
    ///   - batteryLevel: Nivel de batería.
    ///   - cpuUsage: Uso del procesador.
    ///   - totalRAM: RAM total.
    ///   - usedRAM: RAM usada.
    ///   - totalDiskSpace: Almacenamiento total.
    ///   - freeDiskSpace: Almacenamiento libre.
    public init(batteryLevel: Double?, cpuUsage: Double, totalRAM: UInt64, usedRAM: UInt64, totalDiskSpace: UInt64, freeDiskSpace: UInt64) {
        self.batteryLevel = batteryLevel
        self.cpuUsage = cpuUsage
        self.totalRAM = totalRAM
        self.usedRAM = usedRAM
        self.totalDiskSpace = totalDiskSpace
        self.freeDiskSpace = freeDiskSpace
    }
}

/// `MetricsResponse` es la respuesta estándar de la API para métricas del sistema.
public struct MetricsResponse: Codable {
    /// Indicador de éxito de la petición.
    public let success: Bool
    /// Datos de métricas si la operación tuvo éxito.
    public let data: SystemMetrics?
    /// Información del error si la operación falló.
    public let error: ErrorDetail?
}
