import Foundation
import ReplayKit
import CoreMedia

enum PlaygroundCaptureMode: String, CaseIterable, Identifiable {
    case fullDisplay
    case inApp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fullDisplay:
            return "الشاشة كاملة"
        case .inApp:
            return "داخل التطبيق"
        }
    }
}

@MainActor
final class PlaygroundCaptureManager: ObservableObject {
    @Published var captureMode: PlaygroundCaptureMode = .inApp
    @Published private(set) var isCapturing = false
    @Published private(set) var isBusy = false
    @Published private(set) var statusText = "جاهز"
    @Published private(set) var errorText: String?

    @Published private(set) var playbackURL: URL?
    @Published private(set) var hlsReady = false
    @Published private(set) var segmentCount = 0
    @Published private(set) var bufferBytes = 0
    @Published private(set) var firstReadyLatencyText = "—"
    @Published private(set) var httpRequests = 0
    @Published private(set) var playlistRequests = 0
    @Published private(set) var mediaRequests = 0
    @Published private(set) var externalClientRequests = 0
    @Published private(set) var servedBytes = 0
    @Published private(set) var lastClientEndpoint = "—"
    @Published private(set) var lastRequestPath = "—"
    @Published private(set) var playlistText = "—"
    @Published private(set) var initializationBytes = 0
    @Published private(set) var latestSegmentBytes = 0
    @Published private(set) var capturedVideoFrames = 0
    @Published private(set) var capturedAudioBuffers = 0

    private let recorder = RPScreenRecorder.shared()
    private let bridge = PlaygroundLiveBridge()

    #if canImport(ScreenCaptureKit)
    private var fullDisplayController: AnyObject?
    #endif

    init() {
        recorder.isMicrophoneEnabled = false

        bridge.onUpdate = { [weak self] snapshot in
            Task { @MainActor [weak self] in
                guard let self else { return }

                playbackURL = snapshot.playbackURL
                hlsReady = snapshot.isReadyForPlayback
                segmentCount = snapshot.segmentCount
                bufferBytes = snapshot.totalBytes
                firstReadyLatencyText =
                    snapshot.firstReadyLatencyMilliseconds
                    .map {
                        String(
                            format: "%.0f ms",
                            $0
                        )
                    } ?? "—"

                httpRequests = snapshot.totalHTTPRequests
                playlistRequests = snapshot.playlistRequests
                mediaRequests = snapshot.mediaRequests
                externalClientRequests =
                    snapshot.externalClientRequests
                servedBytes = snapshot.servedBytes
                lastClientEndpoint =
                    snapshot.lastClientEndpoint
                lastRequestPath =
                    snapshot.lastRequestPath
                playlistText = snapshot.playlistText
                initializationBytes = snapshot.initializationBytes
                latestSegmentBytes = snapshot.latestSegmentBytes

                if isCapturing {
                    statusText = snapshot.statusText
                }
            }
        }

        bridge.onError = { [weak self] error in
            Task { @MainActor [weak self] in
                self?.handle(error)
            }
        }

        if supportsFullDisplayCapture {
            captureMode = .fullDisplay
            statusText = "جاهز لالتقاط الشاشة الكاملة"
        }
    }

    var isReplayKitAvailable: Bool {
        recorder.isAvailable
    }

    var supportsFullDisplayCapture: Bool {
        #if canImport(ScreenCaptureKit)
        if #available(iOS 27.0, *) {
            return true
        }
        #endif

        return false
    }

    var captureModeDetail: String {
        switch captureMode {
        case .fullDisplay:
            return supportsFullDisplayCapture
                ? "ScreenCaptureKit — يلتقط الشاشة كاملة بعد اختيارك من نافذة النظام."
                : "الشاشة الكاملة تحتاج iOS/iPadOS 27 أو أحدث."

        case .inApp:
            return "ReplayKit — يلتقط محتوى BMW Mirror Pad فقط."
        }
    }

    func toggleCapture() {
        if isCapturing {
            stopCapture()
        } else {
            startCapture()
        }
    }

    func startCapture() {
        guard !isBusy, !isCapturing else { return }

        resetMetrics()
        errorText = nil
        isBusy = true

        statusText = captureMode == .fullDisplay
            ? "بانتظار اختيار الشاشة…"
            : "جارٍ بدء ReplayKit…"

        bridge.start()

        if captureMode == .fullDisplay {
            startFullDisplayCapture()
            return
        }

        startInAppReplayKitCapture()
    }

    private func startInAppReplayKitCapture() {
        guard recorder.isAvailable else {
            errorText =
                "ReplayKit غير متاح على هذا الجهاز."
            statusText = "غير متاح"
            bridge.shutdown()
            return
        }

        let bridge = self.bridge

        recorder.startCapture(
            handler: {
                [weak self] sampleBuffer,
                sampleType,
                error in

                if let error {
                    Task { @MainActor [weak self] in
                        self?.handle(error)
                    }
                    return
                }

                switch sampleType {
                case .video:
                    bridge.appendVideo(sampleBuffer)

                    Task { @MainActor [weak self] in
                        self?.capturedVideoFrames += 1
                    }

                case .audioApp:
                    bridge.appendAudio(sampleBuffer)

                    Task { @MainActor [weak self] in
                        self?.capturedAudioBuffers += 1
                    }

                case .audioMic:
                    break

                @unknown default:
                    break
                }
            },
            completionHandler: {
                [weak self] error in
                Task { @MainActor [weak self] in
                    guard let self else { return }

                    isBusy = false

                    if let error {
                        handle(error)
                        return
                    }

                    isCapturing = true
                    statusText =
                        "ReplayKit يلتقط BMW Mirror Pad"
                }
            }
        )
    }

    func stopCapture() {
        guard !isBusy else { return }

        if captureMode == .fullDisplay {
            stopFullDisplayCapture()
            return
        }

        stopInAppReplayKitCapture()
    }

    private func stopInAppReplayKitCapture() {
        guard recorder.isRecording || isCapturing else {
            bridge.finishCapture()
            isCapturing = false
            return
        }

        isBusy = true
        statusText = "جارٍ إيقاف ReplayKit…"

        recorder.stopCapture {
            [weak self] error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                isBusy = false

                if let error {
                    handle(error)
                    return
                }

                isCapturing = false
                statusText = "تم إيقاف الالتقاط"
                bridge.finishCapture()
            }
        }
    }

    private func startFullDisplayCapture() {
        guard supportsFullDisplayCapture else {
            statusText = "الشاشة الكاملة غير متاحة"
            errorText =
                "ScreenCaptureKit يحتاج iOS/iPadOS 27 أو أحدث."
            isBusy = false
            bridge.shutdown()
            return
        }

        #if canImport(ScreenCaptureKit)
        if #available(iOS 27.0, *) {
            let controller =
                PlaygroundFullDisplayCaptureController()

            let bridge = self.bridge

            controller.onVideoSampleBuffer = {
                [weak self] sampleBuffer in

                bridge.appendVideo(sampleBuffer)

                Task { @MainActor [weak self] in
                    self?.capturedVideoFrames += 1
                }
            }

            controller.onAudioSampleBuffer = {
                [weak self] sampleBuffer in

                bridge.appendAudio(sampleBuffer)

                Task { @MainActor [weak self] in
                    self?.capturedAudioBuffers += 1
                }
            }

            controller.onStateChange = {
                [weak self] state in

                Task { @MainActor [weak self] in
                    self?.statusText = state
                }
            }

            controller.onStarted = { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self else { return }

                    isBusy = false
                    isCapturing = true
                    statusText =
                        "ScreenCaptureKit يلتقط الشاشة الكاملة"
                }
            }

            controller.onStopped = { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self else { return }

                    isBusy = false
                    isCapturing = false
                    statusText = "تم إيقاف الشاشة الكاملة"
                    bridge.finishCapture()
                    fullDisplayController = nil
                }
            }

            controller.onError = { [weak self] error in
                Task { @MainActor [weak self] in
                    self?.handle(error)
                }
            }

            fullDisplayController = controller
            controller.presentFullDisplayPicker()
            return
        }
        #endif

        statusText = "ScreenCaptureKit غير متاح"
        errorText =
            "نسخة النظام أو SDK لا توفر ScreenCaptureKit على iOS."
        isBusy = false
        bridge.shutdown()
    }

    private func stopFullDisplayCapture() {
        #if canImport(ScreenCaptureKit)
        if #available(iOS 27.0, *),
           let controller =
            fullDisplayController
                as? PlaygroundFullDisplayCaptureController {

            isBusy = true
            statusText =
                "جارٍ إيقاف التقاط الشاشة الكاملة…"

            Task {
                await controller.stop()
            }

            return
        }
        #endif

        isCapturing = false
        isBusy = false
        statusText = "متوقف"
        bridge.finishCapture()
        fullDisplayController = nil
    }

    func shutdown() {
        if recorder.isRecording {
            recorder.stopCapture { _ in }
        }

        #if canImport(ScreenCaptureKit)
        if #available(iOS 27.0, *),
           let controller =
            fullDisplayController
                as? PlaygroundFullDisplayCaptureController {

            Task {
                await controller.stop()
            }
        }

        fullDisplayController = nil
        #endif

        isCapturing = false
        isBusy = false
        bridge.shutdown()
    }

    private func resetMetrics() {
        playbackURL = nil
        hlsReady = false
        segmentCount = 0
        bufferBytes = 0
        firstReadyLatencyText = "—"
        httpRequests = 0
        playlistRequests = 0
        mediaRequests = 0
        externalClientRequests = 0
        servedBytes = 0
        lastClientEndpoint = "—"
        lastRequestPath = "—"
        playlistText = "—"
        initializationBytes = 0
        latestSegmentBytes = 0
        capturedVideoFrames = 0
        capturedAudioBuffers = 0
    }

    private func handle(_ error: Error) {
        errorText = error.localizedDescription
        statusText = "خطأ"
        isCapturing = false
        isBusy = false
        bridge.shutdown()

        #if canImport(ScreenCaptureKit)
        fullDisplayController = nil
        #endif
    }
}
