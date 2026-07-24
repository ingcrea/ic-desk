import SwiftUI

/// `MainDashboardView` es la vista principal que unifica la experiencia de IC Desk.
/// Presenta el estado de la conexión, controles rápidos y acceso a los diagnósticos.
/// Respeta el principio de Vista Presentacional apoyada en un ViewModel (Smart/Dumb).
public struct MainDashboardView: View {
    /// El ViewModel inyectado que controla la lógica de negocio y estado global.
    @StateObject private var viewModel = ICDeskViewModel()

    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            Text("IC Desk")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Sub-vista presentacional que muestra el estado
            SessionStatusView(state: viewModel.sessionState)
            
            HStack(spacing: 16) {
                Button(action: {
                    if viewModel.sessionState == .disconnected || viewModel.sessionState == .error {
                        viewModel.connect()
                    } else {
                        viewModel.disconnect()
                    }
                }) {
                    Text(viewModel.sessionState == .disconnected ? "Conectar" : "Desconectar")
                        .padding()
                        .background(viewModel.sessionState == .disconnected ? Color.blue : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            Divider()
            
            // Sub-vista de diagnósticos
            DiagnosticsView(metrics: viewModel.currentMetrics)
            
            Spacer()
        }
        .padding()
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 500)
        #endif
    }
}

struct MainDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        MainDashboardView()
    }
}
