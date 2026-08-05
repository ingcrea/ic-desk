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
                    // En iOS, Bundle.module NO funciona en executableTarget SPM.
                    // Intentamos cargar el logo del bundle principal de la app.
                    LogoView()
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
                    
                    // Batería: macOS muestra telemetría real, iOS muestra enlace a Ajustes
                    #if os(macOS)
                    if let metrics = viewModel.currentMetrics, let battery = metrics.batteryLevel {
                        let pct = Int(battery * 100)
                        let health = metrics.batteryHealth ?? "N/D"
                        let isCharging = health.contains("Cargando")
                        let icon = isCharging ? "battery.100.bolt" :
                            (pct > 80 ? "battery.100" : pct > 50 ? "battery.75" : pct > 20 ? "battery.25" : "battery.0")
                        let color: Color = pct > 50 ? .green : pct > 20 ? .yellow : .red
                        VStack(spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: icon).foregroundColor(color).font(.title3)
                                Text("\(pct)%")
                                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                    .foregroundColor(color)
                            }
                            Text(health).font(.caption).foregroundColor(color.opacity(0.85))
                        }
                    }
                    #else
                    // iOS: Apple no expone la vida de batería a apps de terceros.
                    // Ofrecemos un botón que lleva directo a Ajustes → Batería → Estado.
                    Button(action: {
                        // App-Prefs abre la sección de batería en Ajustes del sistema
                        if let url = URL(string: "App-Prefs:root=BATTERY_USAGE&path=BATTERY_HEALTH"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        } else if let url = URL(string: "App-Prefs:root=BATTERY_USAGE"),
                                  UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        } else if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.green)
                            Text("Ver vida de batería")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.caption)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    #endif
                    
                    // Error de conexión visible
                    if viewModel.sessionState == .error {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Error: no se pudo conectar con desk.ingcrea.com")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 8)
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
            Text("v4.1.30")
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

#if os(iOS)
/// Vista del logo para iOS — NO usa Bundle.module para evitar crash en executableTarget SPM.
/// Carga el PNG del bundle principal de la app de forma segura.
struct LogoView: View {
    var body: some View {
        if let uiImg = UIImage(named: "logo") ?? loadLogoFromMainBundle() {
            Image(uiImage: uiImg)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 32)
        } else {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 28))
                .foregroundColor(.white)
        }
    }
    
    /// Intenta cargar el PNG directamente desde el directorio raíz del bundle
    private func loadLogoFromMainBundle() -> UIImage? {
        if let path = Bundle.main.path(forResource: "logo", ofType: "png") {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
}
#endif
