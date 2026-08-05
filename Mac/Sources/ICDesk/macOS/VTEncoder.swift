import Foundation
import VideoToolbox
import CoreMedia

public class VTEncoder {
    private var compressionSession: VTCompressionSession?
    public var onNALU: ((Data) -> Void)?

    public init(width: Int32, height: Int32) {
        let status = VTCompressionSessionCreate(allocator: kCFAllocatorDefault,
                                                width: width,
                                                height: height,
                                                codecType: kCMVideoCodecType_H264,
                                                encoderSpecification: nil,
                                                imageBufferAttributes: nil,
                                                compressedDataAllocator: nil,
                                                outputCallback: compressionOutputCallback,
                                                refcon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
                                                compressionSessionOut: &compressionSession)
        guard status == noErr, let session = compressionSession else { return }
        
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Baseline_AutoLevel)
        VTCompressionSessionPrepareToEncodeFrames(session)
    }

    public func encode(sampleBuffer: CMSampleBuffer) {
        guard let session = compressionSession, let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let duration = CMSampleBufferGetDuration(sampleBuffer)
        var flags: VTEncodeInfoFlags = []
        VTCompressionSessionEncodeFrame(session, imageBuffer: imageBuffer, presentationTimeStamp: presentationTimeStamp, duration: duration, frameProperties: nil, sourceFrameRefcon: nil, infoFlagsOut: &flags)
    }
}

private func compressionOutputCallback(outputCallbackRefCon: UnsafeMutableRawPointer?,
                                       sourceFrameRefCon: UnsafeMutableRawPointer?,
                                       status: OSStatus,
                                       infoFlags: VTEncodeInfoFlags,
                                       sampleBuffer: CMSampleBuffer?) {
    guard status == noErr, let sampleBuffer = sampleBuffer, let refCon = outputCallbackRefCon else { return }
    let encoder = Unmanaged<VTEncoder>.fromOpaque(refCon).takeUnretainedValue()
    
    var frameData = Data()
    
    // Extract SPS and PPS if it's a keyframe
    let isKeyframe = !((CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[CFString: Any]])?.first?[kCMSampleAttachmentKey_NotSync] as? Bool ?? false)
    
    if isKeyframe, let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer) {
        var spsSize: Int = 0, spsCount: Int = 0
        var spsPtr: UnsafePointer<UInt8>?
        if CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, parameterSetIndex: 0, parameterSetPointerOut: &spsPtr, parameterSetSizeOut: &spsSize, parameterSetCountOut: &spsCount, nalUnitHeaderLengthOut: nil) == noErr {
            frameData.append(contentsOf: [0, 0, 0, 1])
            frameData.append(spsPtr!, count: spsSize)
            
            var ppsSize: Int = 0, ppsCount: Int = 0
            var ppsPtr: UnsafePointer<UInt8>?
            if CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, parameterSetIndex: 1, parameterSetPointerOut: &ppsPtr, parameterSetSizeOut: &ppsSize, parameterSetCountOut: &ppsCount, nalUnitHeaderLengthOut: nil) == noErr {
                frameData.append(contentsOf: [0, 0, 0, 1])
                frameData.append(ppsPtr!, count: ppsSize)
            }
        }
    }
    
    // Extract NALUs from BlockBuffer
    guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
    var lengthAtOffset: Int = 0, totalLength: Int = 0
    var dataPointer: UnsafeMutablePointer<Int8>?
    if CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: &lengthAtOffset, totalLengthOut: &totalLength, dataPointerOut: &dataPointer) == noErr {
        var offset = 0
        let bytes = UnsafeRawPointer(dataPointer!).assumingMemoryBound(to: UInt8.self)
        while offset < totalLength - 4 {
            let naluLength = Int(bytes[offset]) << 24 | Int(bytes[offset+1]) << 16 | Int(bytes[offset+2]) << 8 | Int(bytes[offset+3])
            frameData.append(contentsOf: [0, 0, 0, 1])
            frameData.append(bytes.advanced(by: offset + 4), count: naluLength)
            offset += 4 + naluLength
        }
    }
    
    if !frameData.isEmpty {
        encoder.onNALU?(frameData)
    }
}
