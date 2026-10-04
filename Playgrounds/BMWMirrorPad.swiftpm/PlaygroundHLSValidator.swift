import Foundation
import AVFoundation

struct PlaygroundHLSValidationResult {
    let passed: Bool
    let message: String
    let details: String
}

enum PlaygroundHLSValidator {
    static func validate(
        masterURL: URL
    ) async -> PlaygroundHLSValidationResult {
        do {
            let master = try await fetchText(masterURL)

            guard master.contains("#EXTM3U") else {
                throw ValidationError.invalidMaster("EXTM3U مفقود")
            }

            guard master.contains("CODECS=") else {
                throw ValidationError.invalidMaster("CODECS مفقود")
            }

            guard master.contains("RESOLUTION=") else {
                throw ValidationError.invalidMaster("RESOLUTION مفقود")
            }

            guard master.contains("live.m3u8") else {
                throw ValidationError.invalidMaster("live.m3u8 مفقود")
            }

            guard let mediaURL = URL(
                string: "live.m3u8",
                relativeTo: masterURL
            )?.absoluteURL else {
                throw ValidationError.invalidURL
            }

            let media = try await fetchText(mediaURL)

            guard media.contains("#EXT-X-MAP") else {
                throw ValidationError.invalidMedia("EXT-X-MAP مفقود")
            }

            let extinfCount = media
                .components(separatedBy: "\n")
                .filter { $0.hasPrefix("#EXTINF:") }
                .count

            guard extinfCount >= 3 else {
                throw ValidationError.invalidMedia(
                    "عدد المقاطع أقل من 3"
                )
            }

            guard
                let initURI = extractMapURI(from: media),
                let initURL = URL(
                    string: initURI,
                    relativeTo: mediaURL
                )?.absoluteURL
            else {
                throw ValidationError.invalidMedia(
                    "تعذر قراءة init.mp4"
                )
            }

            guard
                let firstSegmentURI = firstSegmentURI(
                    from: media
                ),
                let firstSegmentURL = URL(
                    string: firstSegmentURI,
                    relativeTo: mediaURL
                )?.absoluteURL
            else {
                throw ValidationError.invalidMedia(
                    "تعذر قراءة أول media segment"
                )
            }

            let initData = try await fetchData(initURL)
            guard
                containsASCII(initData, marker: "ftyp"),
                containsASCII(initData, marker: "moov")
            else {
                throw ValidationError.invalidInitialization
            }

            let segmentData =
                try await fetchData(firstSegmentURL)

            guard
                containsASCII(segmentData, marker: "moof"),
                containsASCII(segmentData, marker: "mdat")
            else {
                throw ValidationError.invalidSegment
            }

            let asset = AVURLAsset(url: masterURL)
            let isPlayable = try await asset.load(.isPlayable)

            guard isPlayable else {
                throw ValidationError.notPlayable
            }

            return PlaygroundHLSValidationResult(
                passed: true,
                message: "HLS صالح ومقبول من AVFoundation",
                details:
                    "master/media/init/segment + AVURLAsset = PASS"
            )
        } catch {
            let nsError = error as NSError

            return PlaygroundHLSValidationResult(
                passed: false,
                message: "فشل التحقق الذاتي",
                details:
                    "\(nsError.domain) (\(nsError.code)): "
                    + nsError.localizedDescription
            )
        }
    }

    private static func fetchText(
        _ url: URL
    ) async throws -> String {
        let data = try await fetchData(url)

        guard let text = String(
            data: data,
            encoding: .utf8
        ) else {
            throw ValidationError.invalidText
        }

        return text
    }

    private static func fetchData(
        _ url: URL
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 8

        let (data, response) =
            try await URLSession.shared.data(for: request)

        guard
            let http = response as? HTTPURLResponse,
            (200...299).contains(http.statusCode)
        else {
            throw ValidationError.httpFailure(
                (response as? HTTPURLResponse)?.statusCode ?? -1
            )
        }

        guard !data.isEmpty else {
            throw ValidationError.emptyResponse
        }

        return data
    }

    private static func extractMapURI(
        from playlist: String
    ) -> String? {
        guard let line = playlist
            .components(separatedBy: "\n")
            .first(where: {
                $0.hasPrefix("#EXT-X-MAP:")
            })
        else {
            return nil
        }

        guard let marker = line.range(of: "URI=\"") else {
            return nil
        }

        let rest = line[marker.upperBound...]

        guard let endQuote = rest.firstIndex(of: "\"") else {
            return nil
        }

        return String(rest[..<endQuote])
    }

    private static func firstSegmentURI(
        from playlist: String
    ) -> String? {
        playlist
            .components(separatedBy: "\n")
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .first {
                !$0.isEmpty
                && !$0.hasPrefix("#")
                && $0.hasSuffix(".m4s")
            }
    }

    private static func containsASCII(
        _ data: Data,
        marker: String
    ) -> Bool {
        let bytes = [UInt8](data)
        let target = [UInt8](marker.utf8)

        guard
            !target.isEmpty,
            bytes.count >= target.count
        else {
            return false
        }

        for index in 0...(bytes.count - target.count) {
            if Array(
                bytes[index..<(index + target.count)]
            ) == target {
                return true
            }
        }

        return false
    }
}

private extension PlaygroundHLSValidator {
    enum ValidationError: LocalizedError {
        case invalidURL
        case invalidText
        case httpFailure(Int)
        case emptyResponse
        case invalidMaster(String)
        case invalidMedia(String)
        case invalidInitialization
        case invalidSegment
        case notPlayable

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "رابط HLS الداخلي غير صالح."
            case .invalidText:
                return "تعذر قراءة playlist كنص."
            case .httpFailure(let code):
                return "HTTP فشل بالحالة \(code)."
            case .emptyResponse:
                return "الخادم أعاد استجابة فارغة."
            case .invalidMaster(let reason):
                return "Master playlist غير صالح: \(reason)."
            case .invalidMedia(let reason):
                return "Media playlist غير صالح: \(reason)."
            case .invalidInitialization:
                return "init.mp4 لا يحتوي ftyp/moov صالحين."
            case .invalidSegment:
                return "Media segment لا يحتوي moof/mdat صالحين."
            case .notPlayable:
                return "AVFoundation رفض HLS كـ playable asset."
            }
        }
    }
}
