import Foundation
import AVFoundation
import CoreMedia
import Network
import UniformTypeIdentifiers
import Darwin

struct PlaygroundLiveBridgeSnapshot {
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

private struct PlaygroundLiveHLSSegment {
    let sequence: Int
    let duration: Double
    let programDateTime: Date
    let data: Data

    var filename: String {
        String(format: "segment-%05d.m4s", sequence)
    }
}

private final class PlaygroundLiveHLSStore {
    private let lock = NSLock()
    private let maxSegments: Int

    private var initializationSegment: Data?
    private var segments: [PlaygroundLiveHLSSegment] = []
    private var nextSequence = 0

    init(maxSegments: Int = 8) {
        self.maxSegments = max(maxSegments, 3)
    }

    func reset() {
        lock.lock()
        initializationSegment = nil
        segments.removeAll(keepingCapacity: true)
        nextSequence = 0
        lock.unlock()
    }

    func setInitializationSegment(_ data: Data) {
        lock.lock()
        initializationSegment = data
        lock.unlock()
    }

    func appendMediaSegment(_ data: Data, duration: Double) {
        lock.lock()

        let segment = PlaygroundLiveHLSSegment(
            sequence: nextSequence,
            duration: max(duration, 0.1),
            programDateTime: Date(),
            data: data
        )

        nextSequence += 1
        segments.append(segment)

        if segments.count > maxSegments {
            segments.removeFirst(segments.count - maxSegments)
        }

        lock.unlock()
    }

    var segmentCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return segments.count
    }

    var totalBytes: Int {
        lock.lock()
        defer { lock.unlock() }

        return (initializationSegment?.count ?? 0)
            + segments.reduce(0) { $0 + $1.data.count }
    }

    var isReadyForPlayback: Bool {
        lock.lock()
        defer { lock.unlock() }
        return initializationSegment != nil && segments.count >= 3
    }

    func response(for path: String) -> (data: Data, contentType: String)? {
        lock.lock()
        defer { lock.unlock() }

        let normalized = path
            .split(separator: "?", maxSplits: 1)
            .first
            .map(String.init) ?? path

        switch normalized {
        case "/", "/live.m3u8":
            return (
                Data(makePlaylistLocked().utf8),
                "application/vnd.apple.mpegurl"
            )

        case "/init.mp4":
            guard let initializationSegment else { return nil }
            return (initializationSegment, "video/mp4")

        default:
            let filename = normalized.hasPrefix("/")
                ? String(normalized.dropFirst())
                : normalized

            guard let segment = segments.first(
                where: { $0.filename == filename }
            ) else {
                return nil
            }

            return (segment.data, "video/mp4")
        }
    }

    private func makePlaylistLocked() -> String {
        let maxDuration = segments.map(\.duration).max() ?? 1
        let targetDuration = max(1, Int(ceil(maxDuration)))
        let firstSequence = segments.first?.sequence ?? 0

        var lines = [
            "#EXTM3U",
            "#EXT-X-VERSION:6",
            "#EXT-X-TARGETDURATION:\(targetDuration)",
            "#EXT-X-MEDIA-SEQUENCE:\(firstSequence)",
            "#EXT-X-INDEPENDENT-SEGMENTS"
        ]

        if initializationSegment != nil {
            lines.append("#EXT-X-MAP:URI=\"init.mp4\"")
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        for segment in segments {
            lines.append(
                "#EXT-X-PROGRAM-DATE-TIME:\(dateFormatter.string(from: segment.programDateTime))"
            )
            lines.append(
                String(
                    format: "#EXTINF:%.3f,",
                    segment.duration
                )
            )
            lines.append(segment.filename)
        }

        return lines.joined(separator: "\n") + "\n"
    }
}

private final class PlaygroundLiveHLSSegmenter: NSObject {
    var onStatistics: (() -> Void)?
    var onError: ((Error) -> Void)?

    private let store: PlaygroundLiveHLSStore
    private let queue = DispatchQueue(
        label: "com.abdulstar.bmwmirror.pad-live-hls",
        qos: .userInitiated
    )

    private var writer: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var sessionStartTime: CMTime = .invalid
    private var writingStarted = false

    init(store: PlaygroundLiveHLSStore) {
        self.store = store
        super.init()
    }

    func reset() {
        queue.async { [weak self] in
            guard let self else { return }

            writer?.cancelWriting()
            writer = nil
            videoInput = nil
            sessionStartTime = .invalid
            writingStarted = false
            store.reset()
            onStatistics?()
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

            guard let writer, writingStarted else {
                writer = nil
                videoInput = nil
                return
            }

            videoInput?.markAsFinished()

            writer.finishWriting { [weak self] in
                guard let self else { return }

                if writer.status == .failed,
                   let error = writer.error {
                    onError?(error)
                }

                self.writer = nil
                self.videoInput = nil
                self.writingStarted = false
                self.onStatistics?()
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

    private func configureWriter(
        from sampleBuffer: CMSampleBuffer
    ) throws {
        guard
            let formatDescription =
                CMSampleBufferGetFormatDescription(sampleBuffer)
        else {
            throw BridgeError.missingVideoFormat
        }

        let dimensions =
            CMVideoFormatDescriptionGetDimensions(formatDescription)

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
                AVVideoAverageBitRateKey: 2_500_000,
                AVVideoExpectedSourceFrameRateKey: 30,
                AVVideoMaxKeyFrameIntervalKey: 30,
                AVVideoMaxKeyFrameIntervalDurationKey: 1.0,
                AVVideoProfileLevelKey:
                    AVVideoProfileLevelH264HighAutoLevel
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

        let startTime =
            CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

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
}

extension PlaygroundLiveHLSSegmenter: AVAssetWriterDelegate {
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
            if let duration,
               duration.isFinite,
               duration > 0 {
                safeDuration = duration
            } else {
                safeDuration = 1
            }

            store.appendMediaSegment(
                segmentData,
                duration: safeDuration
            )

        @unknown default:
            break
        }

        onStatistics?()
    }
}

private extension PlaygroundLiveHLSSegmenter {
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

private struct PlaygroundLiveServerStats {
    let totalRequests: Int
    let playlistRequests: Int
    let mediaRequests: Int
    let externalClientRequests: Int
    let bytesServed: Int
    let lastClientEndpoint: String
    let lastRequestPath: String
}

private final class PlaygroundLiveHTTPServer {
    var onReady: ((URL) -> Void)?
    var onError: ((Error) -> Void)?
    var onStatistics: ((PlaygroundLiveServerStats) -> Void)?

    private let store: PlaygroundLiveHLSStore
    private let queue = DispatchQueue(
        label: "com.abdulstar.bmwmirror.pad-live-http",
        qos: .userInitiated
    )
    private let statsLock = NSLock()

    private var listener: NWListener?
    private var advertisedHost: String?

    private var totalRequests = 0
    private var playlistRequests = 0
    private var mediaRequests = 0
    private var externalClientRequests = 0
    private var bytesServed = 0
    private var lastClientEndpoint = "—"
    private var lastRequestPath = "—"

    init(store: PlaygroundLiveHLSStore) {
        self.store = store
    }

    func start() {
        guard listener == nil else { return }

        resetStatistics()

        do {
            let parameters = NWParameters.tcp
            parameters.includePeerToPeer = true

            let listener = try NWListener(
                using: parameters,
                on: .any
            )

            self.listener = listener

            listener.stateUpdateHandler = {
                [weak self, weak listener] state in
                guard let self else { return }

                switch state {
                case .ready:
                    guard let port = listener?.port else { return }

                    let host =
                        Self.preferredLocalIPv4Address()
                        ?? "127.0.0.1"

                    advertisedHost = host

                    if let url = URL(
                        string:
                            "http://\(host):\(port.rawValue)/live.m3u8"
                    ) {
                        onReady?(url)
                    }

                case .failed(let error):
                    onError?(error)
                    stop()

                default:
                    break
                }
            }

            listener.newConnectionHandler = {
                [weak self] connection in
                self?.handle(connection)
            }

            listener.start(queue: queue)
        } catch {
            onError?(error)
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        advertisedHost = nil
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)

        connection.receive(
            minimumIncompleteLength: 1,
            maximumLength: 64 * 1024
        ) { [weak self, weak connection]
            data, _, _, error in

            guard
                let self,
                let connection
            else {
                return
            }

            if let error {
                connection.cancel()
                onError?(error)
                return
            }

            guard
                let data,
                let request = String(
                    data: data,
                    encoding: .utf8
                ),
                let requestLine =
                    request.components(
                        separatedBy: "\r\n"
                    ).first
            else {
                sendNotFound(on: connection)
                return
            }

            let parts = requestLine.split(separator: " ")
            guard parts.count >= 2 else {
                sendNotFound(on: connection)
                return
            }

            let rawTarget = String(parts[1])
            let path: String

            if let absoluteURL = URL(string: rawTarget),
               absoluteURL.scheme != nil {
                var components = URLComponents(
                    url: absoluteURL,
                    resolvingAgainstBaseURL: false
                )
                path = components?.percentEncodedPath.isEmpty == false
                    ? components!.percentEncodedPath
                    : "/"
            } else {
                path = rawTarget
            }

            let endpoint =
                String(describing: connection.endpoint)

            let remoteHost =
                remoteHost(from: connection.endpoint)

            guard let response = store.response(for: path) else {
                recordRequest(
                    path: path,
                    clientEndpoint: endpoint,
                    remoteHost: remoteHost,
                    bytes: 0
                )
                sendNotFound(on: connection)
                return
            }

            recordRequest(
                path: path,
                clientEndpoint: endpoint,
                remoteHost: remoteHost,
                bytes: response.data.count
            )

            send(
                status: "200 OK",
                contentType: response.contentType,
                body: response.data,
                on: connection
            )
        }
    }

    private func recordRequest(
        path: String,
        clientEndpoint: String,
        remoteHost: String?,
        bytes: Int
    ) {
        statsLock.lock()

        totalRequests += 1
        bytesServed += max(bytes, 0)
        lastClientEndpoint = clientEndpoint
        lastRequestPath = path

        if path.contains(".m3u8") {
            playlistRequests += 1
        } else if path.contains(".m4s")
                    || path.contains("init.mp4") {
            mediaRequests += 1
        }

        if let remoteHost,
           isLikelyExternalClient(host: remoteHost) {
            externalClientRequests += 1
        }

        let snapshot = statisticsLocked()
        statsLock.unlock()

        onStatistics?(snapshot)
    }

    private func isLikelyExternalClient(
        host: String
    ) -> Bool {
        let normalized = host
            .trimmingCharacters(
                in: CharacterSet(
                    charactersIn: "[]"
                )
            )
            .lowercased()

        if normalized == "127.0.0.1"
            || normalized == "::1"
            || normalized == "localhost" {
            return false
        }

        let locals = Set(Self.allLocalIPv4Addresses())
        if locals.contains(normalized) {
            return false
        }

        if let advertisedHost,
           normalized == advertisedHost.lowercased() {
            return false
        }

        return true
    }

    private func remoteHost(
        from endpoint: NWEndpoint
    ) -> String? {
        guard case let .hostPort(host, _) = endpoint else {
            return nil
        }

        return String(describing: host)
    }

    private func sendNotFound(
        on connection: NWConnection
    ) {
        send(
            status: "404 Not Found",
            contentType: "text/plain; charset=utf-8",
            body: Data("Not Found".utf8),
            on: connection
        )
    }

    private func send(
        status: String,
        contentType: String,
        body: Data,
        on connection: NWConnection
    ) {
        let header = """
        HTTP/1.1 \(status)\r
        Content-Type: \(contentType)\r
        Content-Length: \(body.count)\r
        Cache-Control: no-store, no-cache, must-revalidate\r
        Access-Control-Allow-Origin: *\r
        Connection: close\r
        \r
        """

        var response = Data(header.utf8)
        response.append(body)

        connection.send(
            content: response,
            completion: .contentProcessed { _ in
                connection.cancel()
            }
        )
    }

    private func resetStatistics() {
        statsLock.lock()

        totalRequests = 0
        playlistRequests = 0
        mediaRequests = 0
        externalClientRequests = 0
        bytesServed = 0
        lastClientEndpoint = "—"
        lastRequestPath = "—"

        let snapshot = statisticsLocked()
        statsLock.unlock()

        onStatistics?(snapshot)
    }

    private func statisticsLocked()
        -> PlaygroundLiveServerStats {
        PlaygroundLiveServerStats(
            totalRequests: totalRequests,
            playlistRequests: playlistRequests,
            mediaRequests: mediaRequests,
            externalClientRequests: externalClientRequests,
            bytesServed: bytesServed,
            lastClientEndpoint: lastClientEndpoint,
            lastRequestPath: lastRequestPath
        )
    }

    static func preferredLocalIPv4Address() -> String? {
        let addresses = localIPv4AddressPairs()

        if let wifi = addresses.first(
            where: { $0.name == "en0" }
        ) {
            return wifi.address
        }

        return addresses.first?.address
    }

    private static func allLocalIPv4Addresses()
        -> [String] {
        localIPv4AddressPairs().map(\.address)
    }

    private static func localIPv4AddressPairs()
        -> [(name: String, address: String)] {

        var pointer: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&pointer) == 0,
              let first = pointer else {
            return []
        }

        defer {
            freeifaddrs(pointer)
        }

        var current:
            UnsafeMutablePointer<ifaddrs>? = first

        var results:
            [(name: String, address: String)] = []

        while let interfacePointer = current {
            let interface = interfacePointer.pointee
            current = interface.ifa_next

            guard let address = interface.ifa_addr else {
                continue
            }

            guard
                address.pointee.sa_family
                    == UInt8(AF_INET)
            else {
                continue
            }

            let name =
                String(cString: interface.ifa_name)

            guard name != "lo0" else { continue }

            var hostname = [CChar](
                repeating: 0,
                count: Int(NI_MAXHOST)
            )

            let result = getnameinfo(
                address,
                socklen_t(address.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )

            guard result == 0 else { continue }

            results.append(
                (
                    name: name,
                    address:
                        String(cString: hostname)
                )
            )
        }

        return results
    }
}

final class PlaygroundLiveBridge {
    var onUpdate:
        ((PlaygroundLiveBridgeSnapshot) -> Void)?
    var onError: ((Error) -> Void)?

    private let store =
        PlaygroundLiveHLSStore(maxSegments: 8)

    private lazy var segmenter =
        PlaygroundLiveHLSSegmenter(store: store)

    private lazy var server =
        PlaygroundLiveHTTPServer(store: store)

    private let lock = NSLock()

    private var playbackURL: URL?
    private var statusText = "غير مفعّل"
    private var startedAt: Date?
    private var firstReadyLatencyMilliseconds:
        Double?

    private var serverStats =
        PlaygroundLiveServerStats(
            totalRequests: 0,
            playlistRequests: 0,
            mediaRequests: 0,
            externalClientRequests: 0,
            bytesServed: 0,
            lastClientEndpoint: "—",
            lastRequestPath: "—"
        )

    init() {
        segmenter.onStatistics = {
            [weak self] in
            self?.updateReadyLatencyIfNeeded()
            self?.publish()
        }

        segmenter.onError = {
            [weak self] error in
            self?.setStatus(
                "HLS Encoder: \(error.localizedDescription)"
            )
            self?.onError?(error)
        }

        server.onReady = {
            [weak self] url in
            guard let self else { return }

            lock.lock()
            playbackURL = url
            statusText = "Live HLS server جاهز"
            lock.unlock()

            publish()
        }

        server.onStatistics = {
            [weak self] statistics in
            guard let self else { return }

            lock.lock()
            serverStats = statistics
            lock.unlock()

            publish()
        }

        server.onError = {
            [weak self] error in
            self?.setStatus(
                "HLS Server: \(error.localizedDescription)"
            )
            self?.onError?(error)
        }
    }

    func start() {
        lock.lock()
        playbackURL = nil
        statusText = "جارٍ تجهيز Live HLS…"
        startedAt = Date()
        firstReadyLatencyMilliseconds = nil
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
        setStatus(
            "تم إيقاف الالتقاط — المقاطع الأخيرة باقية مؤقتًا"
        )
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

        guard
            firstReadyLatencyMilliseconds == nil,
            let startedAt
        else {
            return
        }

        firstReadyLatencyMilliseconds =
            Date().timeIntervalSince(startedAt) * 1000
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
        let latency =
            firstReadyLatencyMilliseconds
        let stats = serverStats
        lock.unlock()

        onUpdate?(
            PlaygroundLiveBridgeSnapshot(
                statusText: status,
                playbackURL: url,
                segmentCount: store.segmentCount,
                totalBytes: store.totalBytes,
                isReadyForPlayback:
                    store.isReadyForPlayback,
                firstReadyLatencyMilliseconds: latency,
                totalHTTPRequests:
                    stats.totalRequests,
                playlistRequests:
                    stats.playlistRequests,
                mediaRequests:
                    stats.mediaRequests,
                externalClientRequests:
                    stats.externalClientRequests,
                servedBytes:
                    stats.bytesServed,
                lastClientEndpoint:
                    stats.lastClientEndpoint,
                lastRequestPath:
                    stats.lastRequestPath
            )
        )
    }
}
