#if os(macOS)
import Foundation
import ScreenCaptureKit
import CoreGraphics
import CoreMedia
import CoreImage
import CoreVideo

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
    /// Closure que notifica cuando un fotograma comprimido está listo.
    public var onFrameCaptured: ((Data) -> Void)?
    
    private var encoder: VTEncoder?
    private var lastWidth: Int32 = 0
    private var lastHeight: Int32 = 0
    
    /// Delegado invocado cuando se recibe un nuevo frame de video de ScreenCaptureKit.
    public func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let width = Int32(CVPixelBufferGetWidth(imageBuffer))
        let height = Int32(CVPixelBufferGetHeight(imageBuffer))
        
        if encoder == nil || width != lastWidth || height != lastHeight {
            lastWidth = width
            lastHeight = height
            encoder = VTEncoder(width: width, height: height)
            encoder?.onNALU = { [weak self] naluData in
                // Encapsulamos el NALU en nuestro protocolo "IC" para H264
                let w = UInt16(width)
                let h = UInt16(height)
                var packet = Data(capacity: 18 + naluData.count)
                packet.append(contentsOf: [0x49, 0x43, 0x48, 0x32, 0x36, 0x34]) // Magic "ICH264" (indicador para H.264 en Astro)
                packet.append(UInt8(w >> 8)); packet.append(UInt8(w & 0xFF)) // 6: w
                packet.append(UInt8(h >> 8)); packet.append(UInt8(h & 0xFF)) // 8: h
                packet.append(UInt8(0)); packet.append(UInt8(0))             // 10: x (0)
                packet.append(UInt8(0)); packet.append(UInt8(0))             // 12: y (0)
                packet.append(UInt8(w >> 8)); packet.append(UInt8(w & 0xFF)) // 14: sw (screen width)
                packet.append(UInt8(h >> 8)); packet.append(UInt8(h & 0xFF)) // 16: sh (screen height)
                packet.append(naluData)
                self?.onFrameCaptured?(packet)
            }
        }
        
        encoder?.encode(sampleBuffer: sampleBuffer)
    }
}
#endif
