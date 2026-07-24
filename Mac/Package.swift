// swift-tools-version: 5.9
// Manual de Políticas: politicas.md - Mapeo de Arquitectura y Compilación para IC Desk
import PackageDescription

let package = Package(
    name: "ICDesk",
    defaultLocalization: "es",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .executable(
            name: "ICDeskMac",
            targets: ["ICDeskMac"]
        )
    ],
    dependencies: [],
    targets: [
        // Target Principal para macOS e iOS
        .executableTarget(
            name: "ICDeskMac",
            dependencies: [],
            path: "Shared",
            sources: [
                "Models/DeviceInfo.swift",
                "Models/SystemMetrics.swift",
                "Models/RemoteCommand.swift",
                "Models/SessionState.swift",
                "Network/ICDeskWebSocketClient.swift",
                "Utils/AgentIdentifier.swift",
                "Utils/FileTransferManager.swift",
                "ViewModels/ICDeskViewModel.swift",
                "Views/MainDashboardView.swift",
                "Views/SessionStatusView.swift",
                "Views/DiagnosticsView.swift",
                "../macOS/SystemDiagnostics.swift",
                "../macOS/ScreenCaptureManager.swift",
                "../macOS/InputControlManager.swift",
                "../macOS/ShellExecutor.swift",
                "../AppEntry.swift"
            ]
        )
    ]
)
