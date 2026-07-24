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
        let battery = getBatteryLevel()
        let disk = getDiskSpace()
        
        return SystemMetrics(
            batteryLevel: battery,
            cpuUsage: 0.0, // Restringido en iOS sin APIs privadas, se asume 0 para compatibilidad
            totalRAM: 0, // Restringido, requiere host_statistics
            usedRAM: 0,
            totalDiskSpace: disk.total,
            freeDiskSpace: disk.free
        )
    }
    
    /// Obtiene el nivel de batería del iPhone o iPad.
    /// - Returns: Un double entre 0.0 y 1.0 representando la carga.
    private func getBatteryLevel() -> Double? {
        let level = UIDevice.current.batteryLevel
        return level < 0 ? nil : Double(level)
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
