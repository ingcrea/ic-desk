import SwiftUI

/// `DiagnosticsView` es una vista presentacional que muestra un resumen
/// de la salud del sistema basado en los datos de telemetría recopilados.
public struct DiagnosticsView: View {
    /// Las métricas actuales de sistema, si están disponibles.
    public let metrics: SystemMetrics?
    
    public init(metrics: SystemMetrics?) {
        self.metrics = metrics
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Diagnóstico del Sistema")
                .font(.headline)
            
            if let metrics = metrics {
                HStack {
                    Text("CPU:")
                    Spacer()
                    Text(String(format: "%.1f %%", metrics.cpuUsage))
                }
                HStack {
                    Text("RAM:")
                    Spacer()
                    Text("\(metrics.usedRAM / 1_000_000) MB / \(metrics.totalRAM / 1_000_000) MB")
                }
                if let battery = metrics.batteryLevel {
                    HStack {
                        Text("Batería:")
                        Spacer()
                        Text(String(format: "%.0f %%", battery * 100))
                    }
                }
            } else {
                Text("Métricas no disponibles")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
}
