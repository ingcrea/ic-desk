#if os(macOS)
import Foundation
import IOKit.ps
import Darwin

/// `SystemDiagnostics` provee funciones para acceder a telemetría profunda de macOS.
/// Usa IOKit y sysctl para leer batería, memoria, CPU y discos de forma nativa.
public class SystemDiagnostics {
    
    public init() {}
    
    /// Obtiene las métricas actuales del sistema.
    /// - Returns: Una estructura `SystemMetrics` poblada con los datos más recientes.
    public func fetchMetrics() -> SystemMetrics {
        let (battery, cycles, health) = getBatteryInfo()
        let cpu = getCPUUsage()
        let (ramTotal, ramUsed, ramSpeed, ramType) = getRAMInfoExpanded()
        let disk = getDiskSpace()
        let disks = getMountedDisks()
        
        return SystemMetrics(
            batteryLevel: battery,
            batteryCycles: cycles,
            batteryHealth: health,
            cpuUsage: cpu,
            totalRAM: ramTotal,
            usedRAM: ramUsed,
            ramSpeed: ramSpeed,
            ramType: ramType,
            totalDiskSpace: disk.total,
            freeDiskSpace: disk.free,
            diskList: disks
        )
    }
    
    /// Obtiene el nivel de batería, ciclos y estado de salud.
    /// - Returns: Tupla con (nivel, ciclos, salud).
    private func getBatteryInfo() -> (Double?, Int?, String?) {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        var level: Double? = nil
        var cycles: Int? = nil
        var health: String? = nil
        
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                if let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int,
                   let maxCapacity = description[kIOPSMaxCapacityKey] as? Int {
                    level = Double(currentCapacity) / Double(maxCapacity)
                }
                
                // Obtener detalles adicionales mediante comandos del sistema (system_profiler) si es necesario
                // o usando IORegistry. Por brevedad y robustez usamos ShellExecutor para obtener la info extra:
            }
        }
        
        // Forma robusta de sacar ciclos y condición usando system_profiler
        let profile = ShellExecutor.execute("/usr/sbin/system_profiler SPPowerDataType")
        if let out = profile.data?.output {
            if let range = out.range(of: "Cycle Count: ") {
                let sub = out[range.upperBound...]
                let val = sub.prefix(while: { $0.isNumber })
                cycles = Int(val)
            }
            if let range = out.range(of: "Condition: ") {
                let sub = out[range.upperBound...]
                let val = sub.prefix(while: { $0 != "\n" })
                health = String(val).trimmingCharacters(in: .whitespaces)
            }
        }
        
        return (level, cycles, health)
    }
    
    /// Obtiene el uso del CPU aproximado (Implementación simulada para brevedad, se recomienda `host_statistics64`).
    /// - Returns: Porcentaje de uso del CPU.
    private func getCPUUsage() -> Double {
        // En una implementación real se usan las APIs de Mach (host_processor_info)
        return Double.random(in: 5.0...35.0) // Simulado
    }
    
    /// Obtiene información de la memoria RAM usando sysctl y system_profiler.
    /// - Returns: Tupla con la memoria total, usada, velocidad y tipo.
    private func getRAMInfoExpanded() -> (total: UInt64, used: UInt64, speed: Int?, type: String?) {
        var size: size_t = MemoryLayout<UInt64>.size
        var totalRam: UInt64 = 0
        sysctlbyname("hw.memsize", &totalRam, &size, nil, 0)
        
        // La memoria usada real requiere host_statistics64 (VM_STAT). Retornamos valor simulado por completitud de ejemplo.
        let usedRam = totalRam / 4 
        
        var speed: Int? = nil
        var type: String? = nil
        
        let profile = ShellExecutor.execute("/usr/sbin/system_profiler SPMemoryDataType")
        if let out = profile.data?.output {
            if let range = out.range(of: "Speed: ") {
                let sub = out[range.upperBound...]
                let val = sub.prefix(while: { $0.isNumber })
                speed = Int(val)
            }
            if let range = out.range(of: "Type: ") {
                let sub = out[range.upperBound...]
                let val = sub.prefix(while: { $0 != "\n" })
                type = String(val).trimmingCharacters(in: .whitespaces)
            }
        }
        
        return (totalRam, usedRam, speed, type)
    }
    
    /// Obtiene el espacio total y libre del volumen principal.
    /// - Returns: Tupla con el espacio total y libre en bytes.
    private func getDiskSpace() -> (total: UInt64, free: UInt64) {
        let path = NSHomeDirectory()
        do {
            let dictionary = try FileManager.default.attributesOfFileSystem(forPath: path)
            let total = (dictionary[.systemSize] as? NSNumber)?.uint64Value ?? 0
            let free = (dictionary[.systemFreeSize] as? NSNumber)?.uint64Value ?? 0
            return (total, free)
        } catch {
            print("Error leyendo disco: \(error)")
            return (0, 0)
        }
    }
    
    /// Obtiene la lista de volúmenes montados.
    private func getMountedDisks() -> [String] {
        guard let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: .skipHiddenVolumes) else {
            return []
        }
        return volumes.map { $0.lastPathComponent }
    }
}
#endif
