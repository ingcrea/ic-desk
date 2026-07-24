// swift-tools-version: 5.9
// Manual de Políticas: politicas.md - Manifiesto SPM nativo para IC Desk
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
            name: "ICDesk",
            targets: ["ICDesk"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ICDesk",
            path: "Sources/ICDesk"
        )
    ]
)
