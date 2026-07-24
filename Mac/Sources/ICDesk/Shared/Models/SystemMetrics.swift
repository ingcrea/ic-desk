import Foundation

/// `SystemMetrics` encapsula las métricas de rendimiento y estado del sistema en tiempo real.
/// Se usa para reportar el estado de la batería, memoria RAM, CPU y almacenamiento en IC Desk.
public struct SystemMetrics: Codable {
    /// Nivel de batería actual (0.0 a 1.0). Si es nil, el dispositivo no tiene batería o no se pudo leer.
    public let batteryLevel: Double?
    /// Ciclos de carga de la batería.
    public let batteryCycles: Int?
    /// Condición de salud de la batería (ej. "Good", "Normal", "Replace").
    public let batteryHealth: String?
    /// Uso actual del CPU en porcentaje (0.0 a 100.0).
    public let cpuUsage: Double
    /// Memoria RAM total disponible en el sistema en bytes.
    public let totalRAM: UInt64
    /// Memoria RAM actualmente en uso en bytes.
    public let usedRAM: UInt64
    /// Velocidad de la memoria RAM en MHz.
    public let ramSpeed: Int?
    /// Tipo de memoria RAM (ej. DDR4, DDR5).
    public let ramType: String?
    /// Espacio de almacenamiento total en disco principal en bytes.
    public let totalDiskSpace: UInt64
    /// Espacio de almacenamiento disponible en disco principal en bytes.
    public let freeDiskSpace: UInt64
    /// Lista de discos montados en el sistema.
    public let diskList: [String]?

    /// Inicializa una nueva instancia de `SystemMetrics` con los datos de telemetría recopilados.
    public init(batteryLevel: Double?, batteryCycles: Int? = nil, batteryHealth: String? = nil, cpuUsage: Double, totalRAM: UInt64, usedRAM: UInt64, ramSpeed: Int? = nil, ramType: String? = nil, totalDiskSpace: UInt64, freeDiskSpace: UInt64, diskList: [String]? = nil) {
        self.batteryLevel = batteryLevel
        self.batteryCycles = batteryCycles
        self.batteryHealth = batteryHealth
        self.cpuUsage = cpuUsage
        self.totalRAM = totalRAM
        self.usedRAM = usedRAM
        self.ramSpeed = ramSpeed
        self.ramType = ramType
        self.totalDiskSpace = totalDiskSpace
        self.freeDiskSpace = freeDiskSpace
        self.diskList = diskList
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
