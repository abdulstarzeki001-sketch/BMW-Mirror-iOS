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
    let receivedFrames: Int
    let droppedFrames: Int
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
    private var droppedVideoFrames = 0
    private var receivedAudioPackets = 0
    private var smoothedFPS: Double = 0

    init(targetFPS: Double = 30, maxOutputDimension: CGFloat = 1280) {
        self.targetFPS = targetFPS
        self.maxOutputDimension = maxOutputDimension
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }

        lastAcceptedVideoPTS = .invalid
        lastAcceptedWallTime = nil
        receivedVideoFrames = 0
        droppedVideoFrames = 0
        receivedAudioPackets = 0
        smoothedFPS = 0
    }

    func processVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> MediaVideoFrame? {
        let processingStart = CFAbsoluteTimeGetCurrent()
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        lock.lock()
        receivedVideoFrames += 1

        if lastAcceptedVideoPTS.isValid {
            let delta = CMTimeGetSeconds(CMTimeSubtract(presentationTime, lastAcceptedVideoPTS))
            let minimumDelta = 1.0 / targetFPS

            if delta.isFinite, delta >= 0, delta < minimumDelta {
                droppedVideoFrames += 1
                lock.unlock()
                return nil
            }
        }

        lastAcceptedVideoPTS = presentationTime
        let receivedFrames = receivedVideoFrames
        let droppedFrames = droppedVideoFrames
        lock.unlock()

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        let sourceImage = CIImage(cvImageBuffer: imageBuffer)
        let sourceSize = sourceImage.extent.size
        let orientation = videoOrientation(from: sampleBuffer)
        let orientedImage = sourceImage.oriented(orientation)

        let width = orientedImage.extent.width
        let height = orientedImage.extent.height
        let longestSide = max(width, height)
        let scale = longestSide > maxOutputDimension ? maxOutputDimension / longestSide : 1
        let outputImage = scale < 1
            ? orientedImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            : orientedImage

        guard let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        let now = CFAbsoluteTimeGetCurrent()

        lock.lock()
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
            receivedFrames: receivedFrames,
            droppedFrames: droppedFrames,
            presentationTime: presentationTime
        )
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

    private func videoOrientation(from sampleBuffer: CMSampleBuffer) -> CGImagePropertyOrientation {
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
