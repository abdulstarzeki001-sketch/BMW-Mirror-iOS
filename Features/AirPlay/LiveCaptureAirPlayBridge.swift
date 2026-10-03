import Foundation
import CoreMedia

struct LiveCaptureBridgeSnapshot {
    let statusText: String
    let playbackURL: URL?
    let segmentCount: Int
    let totalBytes: Int
    let isReadyForPlayback: Bool
    let firstReadyLatencyMilliseconds: Double?
    let totalHTTPRequests: Int
    let playlistRequests: Int
    let mediaRequests: Int
    let externalClientRequests: Int
    let servedBytes: Int
    let lastClientEndpoint: String
    let lastRequestPath: String
}

final class LiveCaptureAirPlayBridge {
    var onUpdate: ((LiveCaptureBridgeSnapshot) -> Void)?

    private let store = LiveHLSStore(maxSegments: 8)
    private lazy var segmenter = LiveHLSSegmenter(store: store)
    private lazy var server = LiveHLSHTTPServer(store: store)

    private let lock = NSLock()
    private var playbackURL: URL?
    private var statusText = "غير مفعّل"
    private var startedAt: Date?
    private var firstReadyLatencyMilliseconds: Double?
    private var serverStatistics = LiveHLSServerStatistics(
        totalRequests: 0,
        playlistRequests: 0,
        mediaRequests: 0,
        externalClientRequests: 0,
        bytesServed: 0,
        lastClientEndpoint: "—",
        lastRequestPath: "—"
    )

    init() {
        segmenter.onStatistics = { [weak self] _ in
            self?.updateReadyLatencyIfNeeded()
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

        server.onStatistics = { [weak self] statistics in
            guard let self else { return }

            self.lock.lock()
            self.serverStatistics = statistics
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
        startedAt = Date()
        firstReadyLatencyMilliseconds = nil
        serverStatistics = LiveHLSServerStatistics(
            totalRequests: 0,
            playlistRequests: 0,
            mediaRequests: 0,
            externalClientRequests: 0,
            bytesServed: 0,
            lastClientEndpoint: "—",
            lastRequestPath: "—"
        )
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

    private func updateReadyLatencyIfNeeded() {
        guard store.isReadyForPlayback else { return }

        lock.lock()
        defer { lock.unlock() }

        guard firstReadyLatencyMilliseconds == nil,
              let startedAt else {
            return
        }

        firstReadyLatencyMilliseconds = Date()
            .timeIntervalSince(startedAt) * 1000
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
        let latency = firstReadyLatencyMilliseconds
        let serverStats = serverStatistics
        lock.unlock()

        onUpdate?(
            LiveCaptureBridgeSnapshot(
                statusText: status,
                playbackURL: url,
                segmentCount: store.segmentCount,
                totalBytes: store.totalBytes,
                isReadyForPlayback: store.isReadyForPlayback,
                firstReadyLatencyMilliseconds: latency,
                totalHTTPRequests: serverStats.totalRequests,
                playlistRequests: serverStats.playlistRequests,
                mediaRequests: serverStats.mediaRequests,
                externalClientRequests: serverStats.externalClientRequests,
                servedBytes: serverStats.bytesServed,
                lastClientEndpoint: serverStats.lastClientEndpoint,
                lastRequestPath: serverStats.lastRequestPath
            )
        )
    }
}
