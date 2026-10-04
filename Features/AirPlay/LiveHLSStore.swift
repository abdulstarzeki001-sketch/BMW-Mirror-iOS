import Foundation

struct LiveHLSSegment {
    let sequence: Int
    let duration: Double
    let programDateTime: Date
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
    private var videoWidth = 0
    private var videoHeight = 0
    private var codecString = "avc1.640028"

    init(maxSegments: Int = 8) {
        self.maxSegments = max(maxSegments, 3)
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }

        initializationSegment = nil
        segments.removeAll(keepingCapacity: true)
        nextSequence = 0
        videoWidth = 0
        videoHeight = 0
        codecString = "avc1.640028"
    }

    func setInitializationSegment(_ data: Data) {
        lock.lock()
        initializationSegment = data

        if let parsed = Self.h264CodecString(from: data) {
            codecString = parsed
        }

        lock.unlock()
    }

    func setVideoDimensions(width: Int, height: Int) {
        lock.lock()
        videoWidth = width
        videoHeight = height
        lock.unlock()
    }

    @discardableResult
    func appendMediaSegment(_ data: Data, duration: Double) -> LiveHLSSegment {
        lock.lock()
        defer { lock.unlock() }

        let safeDuration = max(duration, 0.1)

        let programDateTime: Date
        if let previous = segments.last {
            programDateTime = previous.programDateTime
                .addingTimeInterval(previous.duration)
        } else {
            programDateTime = Date()
                .addingTimeInterval(-safeDuration)
        }

        let segment = LiveHLSSegment(
            sequence: nextSequence,
            duration: safeDuration,
            programDateTime: programDateTime,
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
        case "/", "/master.m3u8":
            return (
                Data(makeMasterPlaylistLocked().utf8),
                "application/vnd.apple.mpegurl"
            )

        case "/live.m3u8":
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

    private func makeMasterPlaylistLocked() -> String {
        let width = max(videoWidth, 2)
        let height = max(videoHeight, 2)

        return [
            "#EXTM3U",
            "#EXT-X-VERSION:6",
            "#EXT-X-INDEPENDENT-SEGMENTS",
            "#EXT-X-STREAM-INF:BANDWIDTH=5000000,CODECS=\"\(codecString)\",RESOLUTION=\(width)x\(height)",
            "live.m3u8"
        ]
        .joined(separator: "\n") + "\n"
    }

    private func makePlaylistLocked() -> String {
        let maxDuration = segments.map(\.duration).max() ?? 1
        let targetDuration = max(2, Int(ceil(maxDuration)))
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

        for segment in segments {
            lines.append(String(format: "#EXTINF:%.3f,", segment.duration))
            lines.append(segment.filename)
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private static func h264CodecString(from data: Data) -> String? {
        let bytes = [UInt8](data)
        guard bytes.count >= 12 else { return nil }

        let marker: [UInt8] = [0x61, 0x76, 0x63, 0x43]

        for index in 0...(bytes.count - 8) {
            guard Array(bytes[index..<(index + 4)]) == marker else {
                continue
            }

            let profile = bytes[index + 5]
            let compatibility = bytes[index + 6]
            let level = bytes[index + 7]

            return String(
                format: "avc1.%02X%02X%02X",
                profile,
                compatibility,
                level
            )
        }

        return nil
    }
}
