import Foundation
import ReplayKit
import CoreMedia

@MainActor
final class PlaygroundCaptureManager: ObservableObject {
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
    }

    var isReplayKitAvailable: Bool {
        recorder.isAvailable
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

        guard recorder.isAvailable else {
            errorText =
                "ReplayKit غير متاح على هذا الجهاز."
            statusText = "غير متاح"
            return
        }

        resetMetrics()
        errorText = nil
        isBusy = true
        statusText = "جارٍ بدء ReplayKit…"

        bridge.start()

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

        guard recorder.isRecording || isCapturing else {
            bridge.finishCapture()
            isCapturing = false
            return
        }

        isBusy = true
        statusText = "جارٍ إيقاف الالتقاط…"

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

    func shutdown() {
        if recorder.isRecording {
            recorder.stopCapture { _ in }
        }

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
    }
}
