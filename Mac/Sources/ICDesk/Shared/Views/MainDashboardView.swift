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
                // Título con acento y Logo
                HStack(spacing: 8) {
                    #if os(macOS)
                    Image("logo", bundle: .module)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 32)
                    #else
                    // En iOS, cargar el logo desde Bundle.module de forma segura
                    if let uiImg = UIImage(named: "logo", in: Bundle.module, with: nil) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 32)
                    } else {
                        Image(systemName: "desktopcomputer")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    #endif
                    Text("IC ")
                        .foregroundColor(.white) +
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
                    
                    Text(viewModel.supportPIN)
                        .font(.system(size: 36, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    
                    // Batería destacada
                    if let metrics = viewModel.currentMetrics, let battery = metrics.batteryLevel {
                        HStack(spacing: 6) {
                            let pct = Int(battery * 100)
                            let icon = pct > 80 ? "battery.100" : pct > 50 ? "battery.75" : pct > 20 ? "battery.25" : "battery.0"
                            let color: Color = pct > 50 ? .green : pct > 20 ? .yellow : .red
                            Image(systemName: icon)
                                .foregroundColor(color)
                                .font(.title3)
                            Text("\(pct)%")
                                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                .foregroundColor(color)
                        }
                    }
                    
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
                    
                    if let metrics = viewModel.currentMetrics {
                        DiagnosticFeatureRow(icon: "battery.100", text: String(format: "Batería: %.0f%%", (metrics.batteryLevel ?? 0) * 100))
                        DiagnosticFeatureRow(icon: "internaldrive", text: String(format: "Espacio Libre: %.1f GB", Double(metrics.freeDiskSpace) / 1_000_000_000))
                        DiagnosticFeatureRow(icon: "network", text: "WSS: " + (viewModel.sessionState == .connected ? "Estable" : "Desconectado"))
                    } else {
                        Text("Recopilando telemetría...")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 30)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
        }
        // Versión como overlay sobre todo, respetando safe area
        .overlay(alignment: .bottomTrailing) {
            Text("v4.1.23")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
                .fixedSize()
                .padding(.trailing, 48)
                .padding(.bottom, 24)
        }
        .onAppear {
            viewModel.connect()
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 450, minHeight: 650)
        #endif
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
