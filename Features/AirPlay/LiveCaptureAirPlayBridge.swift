import Foundation
import CoreMedia

struct LiveCaptureBridgeSnapshot {
    let statusText: String
    let playbackURL: URL?
    let segmentCount: Int
    let totalBytes: Int
    let isReadyForPlayback: Bool
}

final class LiveCaptureAirPlayBridge {
    var onUpdate: ((LiveCaptureBridgeSnapshot) -> Void)?

    private let store = LiveHLSStore(maxSegments: 8)
    private lazy var segmenter = LiveHLSSegmenter(store: store)
    private lazy var server = LiveHLSHTTPServer(store: store)

    private let lock = NSLock()
    private var playbackURL: URL?
    private var statusText = "غير مفعّل"

    init() {
        segmenter.onStatistics = { [weak self] _ in
            self?.publish()
        }

        segmenter.onError = { [weak self] error in
            self?.setStatus("HLS Encoder: \(error.localizedDescription)")
        }

        server.onReady = { [weak self] url in
            guard let self else { return }

            self.lock.lock()
            self.playbackURL = url
            self.statusText = "HLS server جاهز"
            self.lock.unlock()

            self.publish()
        }

        server.onError = { [weak self] error in
            self?.setStatus("HLS Server: \(error.localizedDescription)")
        }
    }

    func start() {
        lock.lock()
        statusText = "جارٍ تجهيز Live HLS…"
        playbackURL = nil
        lock.unlock()

        segmenter.reset()
        server.start()
        publish()
    }

    func appendVideo(_ sampleBuffer: CMSampleBuffer) {
        segmenter.appendVideo(sampleBuffer)
    }

    func appendAudio(_ sampleBuffer: CMSampleBuffer) {
        segmenter.appendAudio(sampleBuffer)
    }

    func finishCapture() {
        segmenter.finish()
        setStatus("تم إيقاف الالتقاط — آخر مقاطع HLS متاحة مؤقتًا")
    }

    func shutdown() {
        segmenter.finish()
        server.stop()

        lock.lock()
        playbackURL = nil
        statusText = "متوقف"
        lock.unlock()

        publish()
    }

    private func setStatus(_ value: String) {
        lock.lock()
        statusText = value
        lock.unlock()
        publish()
    }

    private func publish() {
        lock.lock()
        let status = statusText
        let url = playbackURL
        lock.unlock()

        onUpdate?(
            LiveCaptureBridgeSnapshot(
                statusText: status,
                playbackURL: url,
                segmentCount: store.segmentCount,
                totalBytes: store.totalBytes,
                isReadyForPlayback: store.isReadyForPlayback
            )
        )
    }
}
