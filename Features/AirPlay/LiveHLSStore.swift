import Foundation

struct LiveHLSSegment {
    let sequence: Int
    let duration: Double
    let data: Data

    var filename: String {
        String(format: "segment-%05d.m4s", sequence)
    }
}

final class LiveHLSStore {
    private let lock = NSLock()
    private let maxSegments: Int

    private var initializationSegment: Data?
    private var segments: [LiveHLSSegment] = []
    private var nextSequence = 0

    init(maxSegments: Int = 8) {
        self.maxSegments = max(maxSegments, 3)
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }

        initializationSegment = nil
        segments.removeAll(keepingCapacity: true)
        nextSequence = 0
    }

    func setInitializationSegment(_ data: Data) {
        lock.lock()
        initializationSegment = data
        lock.unlock()
    }

    @discardableResult
    func appendMediaSegment(_ data: Data, duration: Double) -> LiveHLSSegment {
        lock.lock()
        defer { lock.unlock() }

        let segment = LiveHLSSegment(
            sequence: nextSequence,
            duration: max(duration, 0.1),
            data: data
        )

        nextSequence += 1
        segments.append(segment)

        if segments.count > maxSegments {
            segments.removeFirst(segments.count - maxSegments)
        }

        return segment
    }

    var segmentCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return segments.count
    }

    var totalBytes: Int {
        lock.lock()
        defer { lock.unlock() }

        let initBytes = initializationSegment?.count ?? 0
        return initBytes + segments.reduce(0) { $0 + $1.data.count }
    }

    var isReadyForPlayback: Bool {
        lock.lock()
        defer { lock.unlock() }

        return initializationSegment != nil && !segments.isEmpty
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

            guard let segment = segments.first(where: { $0.filename == filename }) else {
                return nil
            }

            return (segment.data, "video/iso.segment")
        }
    }

    private func makePlaylistLocked() -> String {
        let maxDuration = segments.map(\.duration).max() ?? 1
        let targetDuration = max(1, Int(ceil(maxDuration)))
        let firstSequence = segments.first?.sequence ?? 0

        var lines = [
            "#EXTM3U",
            "#EXT-X-VERSION:7",
            "#EXT-X-TARGETDURATION:\(targetDuration)",
            "#EXT-X-MEDIA-SEQUENCE:\(firstSequence)",
            "#EXT-X-INDEPENDENT-SEGMENTS"
        ]

        if initializationSegment != nil {
            lines.append("#EXT-X-MAP:URI=\"init.mp4\"")
        }

        for segment in segments {
            lines.append(String(format: "#EXTINF:%.3f,", segment.duration))
            lines.append(segment.filename)
        }

        return lines.joined(separator: "\n") + "\n"
    }
}
