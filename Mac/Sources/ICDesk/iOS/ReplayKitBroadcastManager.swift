#if os(iOS)
import Foundation
import ReplayKit
import CoreImage

/// `ReplayKitBroadcastManager` administra la lógica de la transmisión de pantalla en iOS.
/// Utiliza captura in-app para transmitir la vista actual al servidor de soporte.
public class ReplayKitBroadcastManager {
    
    public var onFrameCaptured: ((Data) -> Void)?
    private let ciContext = CIContext(options: nil)
    
    public init() {}
    
    public func startCapture() async throws {
        let recorder = RPScreenRecorder.shared()
        guard recorder.isAvailable else {
            print("Screen recording is not available")
            return
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            recorder.startCapture(handler: { (sampleBuffer, bufferType, error) in
                if let error = error {
                    print("Error capturando frame: \(error)")
                    return
                }
                
                if bufferType == .video, let onFrameCaptured = self.onFrameCaptured {
                    if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
                        if let cgImage = self.ciContext.createCGImage(ciImage, from: ciImage.extent) {
                            let uiImage = UIImage(cgImage: cgImage)
                            if let jpegData = uiImage.jpegData(compressionQuality: 0.5) {
                                onFrameCaptured(jpegData)
                            }
                        }
                    }
                }
            }, completionHandler: { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
    
    public func stopCapture() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            RPScreenRecorder.shared().stopCapture { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
#endif
