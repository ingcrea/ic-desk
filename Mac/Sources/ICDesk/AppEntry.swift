import SwiftUI

/// AppEntry.swift
/// Punto de entrada principal nativo para la aplicación IC Desk en macOS e iOS.
/// Cumplimiento de politicas.md: Documentación narrativa en español.

@main
struct ICDeskApp: App {
    /// Instancia centralizada del ViewModel que orquesta el estado de la app y la conexión WebSocket
    @StateObject private var viewModel = ICDeskViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainDashboardView()
                .environmentObject(viewModel)
                .frame(minWidth: 440, minHeight: 600)
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        #endif
    }
}
