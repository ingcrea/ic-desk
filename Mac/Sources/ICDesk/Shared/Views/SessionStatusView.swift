import SwiftUI

/// `SessionStatusView` es una vista presentacional simple (Dumb View)
/// que renderiza el estado actual de la sesión de IC Desk de forma visual.
public struct SessionStatusView: View {
    /// El estado de sesión proporcionado por la vista padre.
    public let state: SessionState
    
    public init(state: SessionState) {
        self.state = state
    }
    
    public var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            Text(statusText)
                .font(.headline)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
    
    /// Determina el color del indicador según el estado de conexión.
    private var statusColor: Color {
        switch state {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        case .screenSharing: return .purple
        }
    }
    
    /// Devuelve el texto descriptivo del estado de conexión para el usuario.
    private var statusText: String {
        switch state {
        case .connected: return "Conectado"
        case .connecting: return "Conectando..."
        case .disconnected: return "Desconectado"
        case .error: return "Error de Conexión"
        case .screenSharing: return "Compartiendo Pantalla"
        }
    }
}
