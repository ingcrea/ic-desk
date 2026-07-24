#if os(macOS)
import Foundation
import ScreenCaptureKit
import CoreGraphics
import CoreMedia

/// `ScreenCaptureManager` administra la captura de pantalla nativa de alta eficiencia en macOS.
/// Utiliza `ScreenCaptureKit` para lograr un flujo de video estable a 60 FPS.
@available(macOS 12.3, *)
public class ScreenCaptureManager: NSObject, SCStreamOutput, SCStreamDelegate {
    
    /// El flujo de captura de pantalla activo.
    private var stream: SCStream?
    
    /// Inicia la captura de pantalla de la pantalla principal a 60 FPS.
    public func startCapture() async throws {
        let availableContent = try await SCShareableContent.current
        guard let display = availableContent.displays.first else {
            print("No se encontró ninguna pantalla.")
            return
        }
        
        let filter = SCContentFilter(display: display, excludingApplications: [SCRunningApplication](), exceptingWindows: [SCWindow]())
        let configuration = SCStreamConfiguration()
        configuration.width = display.width
        configuration.height = display.height
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60) // 60 FPS
        configuration.queueDepth = 5
        
        stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        
        try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: DispatchQueue(label: "com.icdesk.screencapture"))
        try await stream?.startCapture()
        
        print("Captura de pantalla iniciada exitosamente a 60 FPS.")
    }
    
    /// Detiene la captura de pantalla.
    public func stopCapture() async throws {
        try await stream?.stopCapture()
        stream = nil
        print("Captura de pantalla detenida.")
    }
    
    /// Delegado invocado cuando se recibe un nuevo frame de video de ScreenCaptureKit.
    /// - Parameters:
    ///   - stream: El flujo que origina el frame.
    ///   - sampleBuffer: El buffer de muestra (video frame).
    ///   - type: El tipo de salida (pantalla o audio).
    public func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        // TODO: Comprimir y transmitir el sampleBuffer a través del WebSocket (H264/HEVC)
    }
}
#endif
