import Foundation
import CoreImage
import CoreMedia
import CoreGraphics
import ImageIO
import ReplayKit

struct MediaVideoFrame {
    let image: CGImage
    let sourceSize: CGSize
    let outputSize: CGSize
    let orientationText: String
    let actualFPS: Double
    let processingMilliseconds: Double
    let processedFrames: Int
    let throttledFrames: Int
    let failedFrames: Int
    let presentationTime: CMTime
}

struct MediaAudioMetrics {
    let packetCount: Int
    let sampleCount: Int
    let durationMilliseconds: Double
    let presentationTime: CMTime
}

final class MediaPipeline {
    let targetFPS: Double
    let maxOutputDimension: CGFloat

    private let ciContext = CIContext(options: [
        .cacheIntermediates: false
    ])
    private let lock = NSLock()

    private var lastAcceptedVideoPTS: CMTime = .invalid
    private var lastAcceptedWallTime: CFAbsoluteTime?
    private var receivedVideoFrames = 0
    private var processedVideoFrames = 0
    private var throttledVideoFrames = 0
    private var failedVideoFrames = 0
    private var receivedAudioPackets = 0
    private var smoothedFPS: Double = 0

    init(targetFPS: Double = 30, maxOutputDimension: CGFloat = 1280) {
        self.targetFPS = max(targetFPS, 1)
        self.maxOutputDimension = max(maxOutputDimension, 1)
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }

        lastAcceptedVideoPTS = .invalid
        lastAcceptedWallTime = nil
        receivedVideoFrames = 0
        processedVideoFrames = 0
        throttledVideoFrames = 0
        failedVideoFrames = 0
        receivedAudioPackets = 0
        smoothedFPS = 0
    }

    func processReplayKitVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> MediaVideoFrame? {
        processVideoSampleBuffer(
            sampleBuffer,
            orientation: replayKitOrientation(from: sampleBuffer)
        )
    }

    func processScreenCaptureKitVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> MediaVideoFrame? {
        processVideoSampleBuffer(sampleBuffer, orientation: .up)
    }

    func inspectAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> MediaAudioMetrics {
        lock.lock()
        receivedAudioPackets += 1
        let packetCount = receivedAudioPackets
        lock.unlock()

        let duration = CMSampleBufferGetDuration(sampleBuffer)
        let durationSeconds = duration.isValid ? CMTimeGetSeconds(duration) : 0
        let durationMilliseconds = durationSeconds.isFinite && durationSeconds > 0
            ? durationSeconds * 1000
            : 0

        return MediaAudioMetrics(
            packetCount: packetCount,
            sampleCount: CMSampleBufferGetNumSamples(sampleBuffer),
            durationMilliseconds: durationMilliseconds,
            presentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        )
    }

    private func processVideoSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        orientation: CGImagePropertyOrientation
    ) -> MediaVideoFrame? {
        guard sampleBuffer.isValid else {
            recordFailedFrame()
            return nil
        }

        let processingStart = CFAbsoluteTimeGetCurrent()
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        lock.lock()
        receivedVideoFrames += 1

        if lastAcceptedVideoPTS.isValid {
            let delta = CMTimeGetSeconds(CMTimeSubtract(presentationTime, lastAcceptedVideoPTS))
            let minimumDelta = 1.0 / targetFPS

            if delta.isFinite, delta >= 0, delta < minimumDelta {
                throttledVideoFrames += 1
                lock.unlock()
                return nil
            }
        }

        lastAcceptedVideoPTS = presentationTime
        lock.unlock()

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            recordFailedFrame()
            return nil
        }

        let sourceImage = CIImage(cvImageBuffer: imageBuffer)
        let sourceSize = sourceImage.extent.size
        let orientedImage = sourceImage.oriented(orientation)

        let width = orientedImage.extent.width
        let height = orientedImage.extent.height
        let longestSide = max(width, height)
        let scale = longestSide > maxOutputDimension ? maxOutputDimension / longestSide : 1

        let outputImage: CIImage
        if scale < 1 {
            outputImage = orientedImage.transformed(
                by: CGAffineTransform(scaleX: scale, y: scale)
            )
        } else {
            outputImage = orientedImage
        }

        guard let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            recordFailedFrame()
            return nil
        }

        let now = CFAbsoluteTimeGetCurrent()

        lock.lock()
        processedVideoFrames += 1

        if let previous = lastAcceptedWallTime {
            let interval = now - previous
            if interval > 0 {
                let instantaneousFPS = 1.0 / interval
                smoothedFPS = smoothedFPS == 0
                    ? instantaneousFPS
                    : (smoothedFPS * 0.85) + (instantaneousFPS * 0.15)
            }
        }

        lastAcceptedWallTime = now

        let fps = smoothedFPS
        let processedFrames = processedVideoFrames
        let throttledFrames = throttledVideoFrames
        let failedFrames = failedVideoFrames
        lock.unlock()

        let outputSize = CGSize(width: cgImage.width, height: cgImage.height)
        let processingMilliseconds = (CFAbsoluteTimeGetCurrent() - processingStart) * 1000

        return MediaVideoFrame(
            image: cgImage,
            sourceSize: sourceSize,
            outputSize: outputSize,
            orientationText: orientationLabel(orientation),
            actualFPS: fps,
            processingMilliseconds: processingMilliseconds,
            processedFrames: processedFrames,
            throttledFrames: throttledFrames,
            failedFrames: failedFrames,
            presentationTime: presentationTime
        )
    }

    private func recordFailedFrame() {
        lock.lock()
        failedVideoFrames += 1
        lock.unlock()
    }

    private func replayKitOrientation(from sampleBuffer: CMSampleBuffer) -> CGImagePropertyOrientation {
        guard
            let rawValue = CMGetAttachment(
                sampleBuffer,
                key: RPVideoSampleOrientationKey as CFString,
                attachmentModeOut: nil
            ) as? NSNumber,
            let orientation = CGImagePropertyOrientation(rawValue: rawValue.uint32Value)
        else {
            return .up
        }

        return orientation
    }

    private func orientationLabel(_ orientation: CGImagePropertyOrientation) -> String {
        switch orientation {
        case .up: return "0°"
        case .upMirrored: return "0° mirrored"
        case .down: return "180°"
        case .downMirrored: return "180° mirrored"
        case .left: return "90° يسار"
        case .leftMirrored: return "90° يسار mirrored"
        case .right: return "90° يمين"
        case .rightMirrored: return "90° يمين mirrored"
        @unknown default: return "غير معروف"
        }
    }
}
