#if canImport(ScreenCaptureKit)
import Foundation
import CoreMedia
import ScreenCaptureKit

@available(iOS 27.0, *)
final class FullDisplayCaptureController: NSObject {
    var onFrame: ((MediaVideoFrame) -> Void)?
    var onAudioPacketCount: ((Int) -> Void)?
    var onStateChange: ((String) -> Void)?
    var onStarted: (() -> Void)?
    var onStopped: (() -> Void)?
    var onError: ((Error) -> Void)?

    private let mediaPipeline: MediaPipeline
    private let picker = SCContentSharingPicker.shared
    private let sampleQueue = DispatchQueue(
        label: "com.abdulstar.bmwmirror.screencapturekit.samples",
        qos: .userInteractive
    )

    private var stream: SCStream?

    init(mediaPipeline: MediaPipeline) {
        self.mediaPipeline = mediaPipeline
        super.init()
    }

    func presentFullDisplayPicker() {
        var configuration = SCContentSharingPickerConfiguration()
        configuration.allowsChangingSelectedContent = true

        picker.defaultConfiguration = configuration
        picker.add(self)
        picker.isActive = true

        onStateChange?("اختر الشاشة من نافذة مشاركة النظام")
        picker.present()
    }

    func stop() async {
        picker.remove(self)
        picker.isActive = false

        guard let stream else {
            onStopped?()
            return
        }

        do {
            try await stream.stopCapture()
            self.stream = nil
            onStopped?()
        } catch {
            self.stream = nil
            onError?(error)
        }
    }

    private func startStream(with filter: SCContentFilter) {
        Task { [weak self] in
            guard let self else { return }

            if let existing = self.stream {
                try? await existing.stopCapture()
                self.stream = nil
            }

            let configuration = SCStreamConfiguration()
            configuration.minimumFrameInterval = CMTime(value: 1, timescale: 30)
            configuration.queueDepth = 3
            configuration.capturesAudio = true

            let newStream = SCStream(
                filter: filter,
                configuration: configuration,
                delegate: self
            )

            do {
                try newStream.addStreamOutput(
                    self,
                    type: .screen,
                    sampleHandlerQueue: sampleQueue
                )

                try newStream.addStreamOutput(
                    self,
                    type: .audio,
                    sampleHandlerQueue: sampleQueue
                )

                self.stream = newStream
                try await newStream.startCapture()

                self.onStateChange?("التقاط الشاشة الكاملة يعمل")
                self.onStarted?()
            } catch {
                self.stream = nil
                self.onError?(error)
            }
        }
    }
}

@available(iOS 27.0, *)
extension FullDisplayCaptureController: SCContentSharingPickerObserver {
    func contentSharingPicker(
        _ picker: SCContentSharingPicker,
        didUpdateWith filter: SCContentFilter,
        for stream: SCStream?
    ) {
        mediaPipeline.reset()
        startStream(with: filter)
    }

    func contentSharingPicker(
        _ picker: SCContentSharingPicker,
        didCancelFor stream: SCStream?
    ) {
        picker.remove(self)
        picker.isActive = false
        onStateChange?("تم إلغاء اختيار الشاشة")
        onStopped?()
    }

    func contentSharingPickerStartDidFailWithError(_ error: Error) {
        picker.remove(self)
        picker.isActive = false
        onError?(error)
    }
}

@available(iOS 27.0, *)
extension FullDisplayCaptureController: SCStreamOutput {
    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard sampleBuffer.isValid else { return }

        switch type {
        case .screen:
            if let frame = mediaPipeline.processScreenCaptureKitVideoSampleBuffer(sampleBuffer) {
                onFrame?(frame)
            }

        case .audio:
            let metrics = mediaPipeline.inspectAudioSampleBuffer(sampleBuffer)
            onAudioPacketCount?(metrics.packetCount)

        default:
            break
        }
    }
}

@available(iOS 27.0, *)
extension FullDisplayCaptureController: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        self.stream = nil
        onError?(error)
    }
}
#endif
