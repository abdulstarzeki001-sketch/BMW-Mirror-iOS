import Foundation
import Combine
import ReplayKit
import CoreMedia
import CoreGraphics

@MainActor
final class ScreenCaptureManager: ObservableObject {
    @Published var captureMode: CaptureMode = .inAppLegacy

    @Published private(set) var isCapturing = false
    @Published private(set) var isBusy = false
    @Published private(set) var latestFrame: CGImage?
    @Published private(set) var frameCount = 0
    @Published private(set) var droppedFrameCount = 0
    @Published private(set) var failedFrameCount = 0
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

    #if canImport(ScreenCaptureKit)
    private var fullDisplayController: AnyObject?
    #endif

    init() {
        recorder.isMicrophoneEnabled = false

        if supportsFullDisplayCapture {
            captureMode = .fullDisplay
            statusText = "جاهز لالتقاط الشاشة الكاملة"
        } else {
            captureMode = .inAppLegacy
            statusText = "وضع ReplayKit داخل التطبيق"
        }
    }

    var supportsFullDisplayCapture: Bool {
        #if canImport(ScreenCaptureKit)
        if #available(iOS 27.0, *) {
            return true
        }
        #endif
        return false
    }

    var modeDetailText: String {
        switch captureMode {
        case .fullDisplay:
            return supportsFullDisplayCapture
                ? "ScreenCaptureKit يستطيع التقاط الشاشة كاملة بعد اختيار المستخدم."
                : "التقاط الشاشة الكاملة يحتاج iOS 27 أو أحدث."

        case .inAppLegacy:
            return "ReplayKit هنا يلتقط محتوى BMW Mirror نفسه، وليس كل تطبيقات iPhone."
        }
    }

    func toggleCapture() {
        guard !isBusy else { return }

        if isCapturing {
            stopCapture()
        } else {
            startCapture()
        }
    }

    func startCapture() {
        guard !isCapturing, !isBusy else { return }

        errorText = nil
        resetMetrics()
        mediaPipeline.reset()

        switch captureMode {
        case .fullDisplay:
            startFullDisplayCapture()

        case .inAppLegacy:
            startReplayKitCapture()
        }
    }

    func stopCapture() {
        guard isCapturing || isBusy else { return }

        switch captureMode {
        case .fullDisplay:
            stopFullDisplayCapture()

        case .inAppLegacy:
            stopReplayKitCapture()
        }
    }

    private func startReplayKitCapture() {
        guard recorder.isAvailable else {
            statusText = "ReplayKit غير متاح"
            errorText = "ReplayKit غير متاح حاليًا على هذا الجهاز."
            return
        }

        isBusy = true
        statusText = "جارٍ بدء ReplayKit…"

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
                    guard let frame = pipeline.processReplayKitVideoSampleBuffer(sampleBuffer) else {
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

                    self.isBusy = false

                    if let error {
                        self.handleCaptureError(error)
                        return
                    }

                    self.isCapturing = true
                    self.statusText = "ReplayKit يعمل داخل التطبيق"
                }
            }
        )
    }

    private func stopReplayKitCapture() {
        guard recorder.isRecording || isCapturing else {
            finishStoppedState()
            return
        }

        isBusy = true
        statusText = "جارٍ إيقاف ReplayKit…"

        recorder.stopCapture { [weak self] error in
            Task { @MainActor in
                guard let self else { return }

                self.isBusy = false

                if let error {
                    self.handleCaptureError(error)
                    return
                }

                self.finishStoppedState()
            }
        }
    }

    private func startFullDisplayCapture() {
        guard supportsFullDisplayCapture else {
            statusText = "الشاشة الكاملة غير مدعومة"
            errorText = "هذا الوضع يحتاج iOS 27 أو أحدث وScreenCaptureKit."
            return
        }

        #if canImport(ScreenCaptureKit)
        if #available(iOS 27.0, *) {
            let controller = FullDisplayCaptureController(mediaPipeline: mediaPipeline)

            controller.onFrame = { [weak self] frame in
                Task { @MainActor [weak self] in
                    self?.consume(frame: frame)
                }
            }

            controller.onAudioPacketCount = { [weak self] count in
                Task { @MainActor [weak self] in
                    self?.audioPacketCount = count
                }
            }

            controller.onStateChange = { [weak self] state in
                Task { @MainActor [weak self] in
                    self?.statusText = state
                }
            }

            controller.onStarted = { [weak self] in
                Task { @MainActor [weak self] in
                    self?.isBusy = false
                    self?.isCapturing = true
                    self?.statusText = "التقاط الشاشة الكاملة يعمل"
                }
            }

            controller.onStopped = { [weak self] in
                Task { @MainActor [weak self] in
                    self?.isBusy = false
                    self?.finishStoppedState()
                }
            }

            controller.onError = { [weak self] error in
                Task { @MainActor [weak self] in
                    self?.handleCaptureError(error)
                }
            }

            fullDisplayController = controller
            isBusy = true
            statusText = "بانتظار اختيار الشاشة…"
            controller.presentFullDisplayPicker()
            return
        }
        #endif

        statusText = "ScreenCaptureKit غير متاح"
        errorText = "نسخة Xcode/iOS الحالية لا توفر مسار ScreenCaptureKit المطلوب."
    }

    private func stopFullDisplayCapture() {
        #if canImport(ScreenCaptureKit)
        if #available(iOS 27.0, *),
           let controller = fullDisplayController as? FullDisplayCaptureController {
            isBusy = true
            statusText = "جارٍ إيقاف التقاط الشاشة الكاملة…"

            Task {
                await controller.stop()
            }
            return
        }
        #endif

        finishStoppedState()
    }

    private func consume(frame: MediaVideoFrame) {
        latestFrame = frame.image
        frameCount = frame.processedFrames
        droppedFrameCount = frame.throttledFrames
        failedFrameCount = frame.failedFrames
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
        failedFrameCount = 0
        audioPacketCount = 0
        frameSizeText = "—"
        sourceSizeText = "—"
        orientationText = "—"
        actualFPSText = "0.0"
        processingLatencyText = "—"
    }

    private func finishStoppedState() {
        isCapturing = false
        isBusy = false
        statusText = "متوقف"

        #if canImport(ScreenCaptureKit)
        fullDisplayController = nil
        #endif
    }

    private func handleCaptureError(_ error: Error) {
        isCapturing = false
        isBusy = false
        statusText = "حدث خطأ"
        errorText = error.localizedDescription

        #if canImport(ScreenCaptureKit)
        fullDisplayController = nil
        #endif
    }
}
