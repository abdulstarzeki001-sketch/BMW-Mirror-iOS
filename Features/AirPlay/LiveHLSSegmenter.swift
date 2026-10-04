import Foundation
import AVFoundation
import CoreMedia
import UniformTypeIdentifiers

final class LiveHLSSegmenter: NSObject {
    struct Statistics {
        let mediaSegmentCount: Int
        let totalBytes: Int
    }

    var onStatistics: ((Statistics) -> Void)?
    var onError: ((Error) -> Void)?

    private let store: LiveHLSStore
    private let queue = DispatchQueue(
        label: "com.abdulstar.bmwmirror.hls-segmenter",
        qos: .userInitiated
    )

    private var writer: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var sessionStartTime: CMTime = .invalid
    private var writingStarted = false

    init(store: LiveHLSStore) {
        self.store = store
        super.init()
    }

    func reset() {
        queue.async { [weak self] in
            guard let self else { return }

            self.writer?.cancelWriting()
            self.writer = nil
            self.videoInput = nil
            self.sessionStartTime = .invalid
            self.writingStarted = false
            self.store.reset()
            self.publishStatistics()
        }
    }

    func appendVideo(_ sampleBuffer: CMSampleBuffer) {
        queue.async { [weak self] in
            self?.appendVideoLocked(sampleBuffer)
        }
    }

    func appendAudio(_ sampleBuffer: CMSampleBuffer) {
        queue.async { [weak self] in
            self?.appendAudioLocked(sampleBuffer)
        }
    }

    func finish() {
        queue.async { [weak self] in
            guard let self else { return }

            guard let writer = self.writer, self.writingStarted else {
                self.writer = nil
                self.videoInput = nil
                return
            }

            self.videoInput?.markAsFinished()

            writer.finishWriting { [weak self] in
                guard let self else { return }

                if writer.status == .failed, let error = writer.error {
                    self.onError?(error)
                }

                self.writer = nil
                self.videoInput = nil
                self.writingStarted = false
                self.publishStatistics()
            }
        }
    }

    private func appendVideoLocked(_ sampleBuffer: CMSampleBuffer) {
        guard sampleBuffer.isValid else { return }

        do {
            if writer == nil {
                try configureWriter(from: sampleBuffer)
            }

            guard
                let writer,
                let videoInput,
                writer.status == .writing,
                videoInput.isReadyForMoreMediaData
            else {
                return
            }

            guard videoInput.append(sampleBuffer) else {
                if let error = writer.error {
                    onError?(error)
                }
                return
            }


        } catch {
            onError?(error)
        }
    }

    private func appendAudioLocked(_ sampleBuffer: CMSampleBuffer) {
        // Intentionally video-only for the live AirPlay transport.
        // A silent/empty AAC input can prevent AVAssetWriter from
        // finalizing CMAF/HLS segments on real devices.
        _ = sampleBuffer
    }

    private func configureWriter(from sampleBuffer: CMSampleBuffer) throws {
        guard
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
        else {
            throw BridgeError.missingVideoFormat
        }

        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        let width = evenDimension(Int(dimensions.width))
        let height = evenDimension(Int(dimensions.height))

        guard width > 0, height > 0 else {
            throw BridgeError.invalidVideoDimensions
        }

        guard let mp4Type = UTType(AVFileType.mp4.rawValue) else {
            throw BridgeError.missingMP4Type
        }

        let writer = AVAssetWriter(contentType: mp4Type)
        writer.outputFileTypeProfile = .mpeg4AppleHLS
        writer.preferredOutputSegmentInterval = CMTime(
            seconds: 1.0,
            preferredTimescale: 600
        )
        writer.delegate = self

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 4_000_000,
                AVVideoExpectedSourceFrameRateKey: 30,
                AVVideoMaxKeyFrameIntervalKey: 30,
                AVVideoMaxKeyFrameIntervalDurationKey: 1.0,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]

        let videoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: videoSettings,
            sourceFormatHint: formatDescription
        )
        videoInput.expectsMediaDataInRealTime = true

        guard writer.canAdd(videoInput) else {
            throw BridgeError.cannotAddVideoInput
        }
        writer.add(videoInput)

        let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        writer.initialSegmentStartTime = startTime

        guard writer.startWriting() else {
            throw writer.error ?? BridgeError.cannotStartWriter
        }

        writer.startSession(atSourceTime: startTime)

        self.writer = writer
        self.videoInput = videoInput
        self.sessionStartTime = startTime
        self.writingStarted = true
    }

    private func evenDimension(_ value: Int) -> Int {
        guard value > 1 else { return value }
        return value.isMultiple(of: 2) ? value : value - 1
    }

    private func publishStatistics() {
        onStatistics?(
            Statistics(
                mediaSegmentCount: store.segmentCount,
                totalBytes: store.totalBytes
            )
        )
    }
}

extension LiveHLSSegmenter: AVAssetWriterDelegate {
    func assetWriter(
        _ writer: AVAssetWriter,
        didOutputSegmentData segmentData: Data,
        segmentType: AVAssetSegmentType,
        segmentReport: AVAssetSegmentReport?
    ) {
        switch segmentType {
        case .initialization:
            store.setInitializationSegment(segmentData)

        case .separable:
            let duration = segmentReport?
                .trackReports
                .first(where: { $0.mediaType == .video })
                .map { CMTimeGetSeconds($0.duration) }

            let safeDuration: Double
            if let duration, duration.isFinite, duration > 0 {
                safeDuration = duration
            } else {
                safeDuration = 1.0
            }

            store.appendMediaSegment(
                segmentData,
                duration: safeDuration
            )

        @unknown default:
            break
        }

        publishStatistics()
    }
}

private extension LiveHLSSegmenter {
    enum BridgeError: LocalizedError {
        case missingVideoFormat
        case invalidVideoDimensions
        case missingMP4Type
        case cannotAddVideoInput
        case cannotStartWriter

        var errorDescription: String? {
            switch self {
            case .missingVideoFormat:
                return "تعذر قراءة صيغة إطار الفيديو."
            case .invalidVideoDimensions:
                return "أبعاد الفيديو غير صالحة."
            case .missingMP4Type:
                return "تعذر تكوين نوع MPEG-4."
            case .cannotAddVideoInput:
                return "AVAssetWriter رفض مدخل الفيديو."
            case .cannotStartWriter:
                return "تعذر بدء AVAssetWriter."
            }
        }
    }
}
