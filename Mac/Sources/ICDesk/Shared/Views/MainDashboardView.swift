import SwiftUI

/// `MainDashboardView` es la vista principal que unifica la experiencia de IC Desk.
/// Presenta el estado de la conexión, controles rápidos y acceso a los diagnósticos.
/// Respeta el principio de Vista Presentacional apoyada en un ViewModel (Smart/Dumb).
public struct MainDashboardView: View {
    /// El ViewModel inyectado que controla la lógica de negocio y estado global.
    @StateObject private var viewModel = ICDeskViewModel()

    public init() {}

    public var body: some View {
        ZStack {
            // Fondo degradado
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.05, green: 0.1, blue: 0.2), Color.black]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Título con acento
                HStack(spacing: 0) {
                    Text("IC ")
                        .foregroundColor(.white)
                    Text("Desk")
                        .foregroundColor(Color.blue)
                }
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .padding(.top, 20)
                
                // Tarjeta Glassmorphism
                VStack(spacing: 20) {
                    Text("Tu PIN de Soporte")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(generateSupportPIN())
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(4)
                    
                    SessionStatusView(state: viewModel.sessionState)
                    
                    Button(action: {
                        if viewModel.sessionState == .disconnected || viewModel.sessionState == .error {
                            viewModel.connect()
                        } else {
                            viewModel.disconnect()
                        }
                    }) {
                        Text(viewModel.sessionState == .disconnected ? "Conectar al Servidor" : "Desconectar")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(viewModel.sessionState == .disconnected ? Color.blue.opacity(0.8) : Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                
                // Lista de características de diagnóstico visuales
                VStack(alignment: .leading, spacing: 12) {
                    Text("Diagnósticos en tiempo real")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 4)
                    
                    DiagnosticFeatureRow(icon: "cpu", text: "Telemetría de CPU y Memoria")
                    DiagnosticFeatureRow(icon: "battery.100", text: "Salud y Ciclos de Batería")
                    DiagnosticFeatureRow(icon: "internaldrive", text: "Monitoreo de Discos")
                    DiagnosticFeatureRow(icon: "network", text: "Conexión Segura (WSS)")
                }
                .padding(.horizontal, 30)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
        }
        #if os(macOS)
        .frame(minWidth: 450, minHeight: 650)
        #endif
    }
    
    /// Genera un PIN aleatorio de 6 dígitos para soporte.
    private func generateSupportPIN() -> String {
        // En un caso real esto se obtendría del servidor o se sincronizaría.
        let randomPIN = String(format: "%06d", Int.random(in: 100000...999999))
        return randomPIN
    }
}

/// Fila reutilizable para las características de diagnóstico
struct DiagnosticFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            Text(text)
                .foregroundColor(.white.opacity(0.9))
                .font(.subheadline)
        }
    }
}

struct MainDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        MainDashboardView()
    }
}
