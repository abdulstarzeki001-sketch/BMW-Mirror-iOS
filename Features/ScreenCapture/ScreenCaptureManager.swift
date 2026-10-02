import Foundation
import Combine
import ReplayKit
import CoreMedia
import CoreGraphics

@MainActor
final class ScreenCaptureManager: ObservableObject {
    @Published private(set) var isCapturing = false
    @Published private(set) var latestFrame: CGImage?
    @Published private(set) var frameCount = 0
    @Published private(set) var droppedFrameCount = 0
    @Published private(set) var audioPacketCount = 0
    @Published private(set) var frameSizeText = "—"
    @Published private(set) var sourceSizeText = "—"
    @Published private(set) var orientationText = "—"
    @Published private(set) var actualFPSText = "0.0"
    @Published private(set) var processingLatencyText = "—"
    @Published private(set) var statusText = "جاهز"
    @Published private(set) var errorText: String?

    let targetFPS = 30

    private let recorder = RPScreenRecorder.shared()
    private let mediaPipeline = MediaPipeline(targetFPS: 30, maxOutputDimension: 1280)

    init() {
        recorder.isMicrophoneEnabled = false
    }

    func toggleCapture() {
        isCapturing ? stopCapture() : startCapture()
    }

    func startCapture() {
        guard recorder.isAvailable else {
            statusText = "التقاط الشاشة غير متاح"
            errorText = "iOS لا يسمح بالتقاط الشاشة حاليًا على هذا الجهاز."
            return
        }

        errorText = nil
        statusText = "طلب إذن الالتقاط…"
        resetMetrics()
        mediaPipeline.reset()

        let pipeline = mediaPipeline

        recorder.startCapture(
            handler: { [weak self] sampleBuffer, sampleType, error in
                if let error {
                    Task { @MainActor [weak self] in
                        self?.handleCaptureError(error)
                    }
                    return
                }

                switch sampleType {
                case .video:
                    guard let frame = pipeline.processVideoSampleBuffer(sampleBuffer) else {
                        return
                    }

                    Task { @MainActor [weak self] in
                        self?.consume(frame: frame)
                    }

                case .audioApp:
                    let metrics = pipeline.inspectAudioSampleBuffer(sampleBuffer)

                    Task { @MainActor [weak self] in
                        self?.audioPacketCount = metrics.packetCount
                    }

                case .audioMic:
                    break

                @unknown default:
                    break
                }
            },
            completionHandler: { [weak self] error in
                Task { @MainActor in
                    guard let self else { return }

                    if let error {
                        self.handleCaptureError(error)
                        return
                    }

                    self.isCapturing = true
                    self.statusText = "مسار الوسائط يعمل"
                }
            }
        )
    }

    func stopCapture() {
        guard isCapturing else { return }

        statusText = "جارٍ إيقاف الالتقاط…"

        recorder.stopCapture { [weak self] error in
            Task { @MainActor in
                guard let self else { return }

                if let error {
                    self.handleCaptureError(error)
                    return
                }

                self.isCapturing = false
                self.statusText = "متوقف"
            }
        }
    }

    private func consume(frame: MediaVideoFrame) {
        latestFrame = frame.image
        frameCount = frame.receivedFrames - frame.droppedFrames
        droppedFrameCount = frame.droppedFrames
        frameSizeText = "\(Int(frame.outputSize.width)) × \(Int(frame.outputSize.height))"
        sourceSizeText = "\(Int(frame.sourceSize.width)) × \(Int(frame.sourceSize.height))"
        orientationText = frame.orientationText
        actualFPSText = String(format: "%.1f", frame.actualFPS)
        processingLatencyText = String(format: "%.1f ms", frame.processingMilliseconds)
    }

    private func resetMetrics() {
        latestFrame = nil
        frameCount = 0
        droppedFrameCount = 0
        audioPacketCount = 0
        frameSizeText = "—"
        sourceSizeText = "—"
        orientationText = "—"
        actualFPSText = "0.0"
        processingLatencyText = "—"
    }

    private func handleCaptureError(_ error: Error) {
        isCapturing = false
        statusText = "حدث خطأ"
        errorText = error.localizedDescription
    }
}
