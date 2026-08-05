#if os(iOS)
import Foundation
import UIKit

/// `iOSDiagnostics` se encarga de recopilar información de sistema exclusiva para iOS.
/// Utiliza `UIDevice` y APIs de Foundation para diagnosticar el estado del dispositivo.
public class iOSDiagnostics {
    
    public init() {
        // Habilitar monitoreo de batería (requerido en iOS para leer el nivel)
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    /// Recopila las métricas de estado de un dispositivo iOS.
    /// - Returns: Objeto `SystemMetrics` con los datos recopilados.
    public func fetchMetrics() -> SystemMetrics {
        let (batteryLvl, batteryHealth, isCharging) = getBatteryInfo()
        let disk = getDiskSpace()
        let chargingNote = isCharging ? " Cargando" : ""
        
        return SystemMetrics(
            batteryLevel: batteryLvl,
            batteryHealth: batteryHealth + chargingNote,
            cpuUsage: 0.0,
            totalRAM: 0,
            usedRAM: 0,
            totalDiskSpace: disk.total,
            freeDiskSpace: disk.free
        )
    }
    
    /// Obtiene el nivel de carga y el estado de la batería del iPhone.
    /// - Returns: Tupla con nivel (0.0-1.0), texto de salud cualitativo y estado de carga.
    private func getBatteryInfo() -> (level: Double?, health: String, isCharging: Bool) {
        let level = UIDevice.current.batteryLevel
        let state = UIDevice.current.batteryState
        
        let isCharging = (state == .charging || state == .full)
        
        guard level >= 0 else { return (nil, "Desconocida", isCharging) }
        
        let pct = Double(level)
        let health: String
        switch pct {
        case 0.80...: health = "Excelente"
        case 0.50...: health = "Buena"
        case 0.20...: health = "Baja"
        default:      health = "Critica"
        }
        return (pct, health, isCharging)
    }
    
    /// Inspecciona el sistema de archivos del contenedor de la App para calcular espacio.
    /// - Returns: Tupla de espacio total y libre en bytes.
    private func getDiskSpace() -> (total: UInt64, free: UInt64) {
        let path = NSHomeDirectory()
        do {
            let dictionary = try FileManager.default.attributesOfFileSystem(forPath: path)
            let total = (dictionary[.systemSize] as? NSNumber)?.uint64Value ?? 0
            let free = (dictionary[.systemFreeSize] as? NSNumber)?.uint64Value ?? 0
            return (total, free)
        } catch {
            print("Error leyendo disco en iOS: \(error)")
            return (0, 0)
        }
    }
}
#endif
