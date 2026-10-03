import Foundation

@MainActor
final class LegacyBroadcastMonitor: ObservableObject {
    @Published private(set) var isReachable = false
    @Published private(set) var statusText = "بانتظار Broadcast Extension"
    @Published private(set) var latencyText = "—"
    @Published private(set) var probeCount = 0

    private var monitorTask: Task<Void, Never>?

    deinit {
        monitorTask?.cancel()
    }

    func start(url: URL) {
        stop()

        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.probe(url: url)

                try? await Task.sleep(
                    nanoseconds: 1_000_000_000
                )
            }
        }
    }

    func stop() {
        monitorTask?.cancel()
        monitorTask = nil
    }

    private func probe(url: URL) async {
        probeCount += 1

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 1.5

        let started = ContinuousClock.now

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let elapsed = started.duration(to: .now)
            let milliseconds = Double(elapsed.components.seconds) * 1000
                + Double(elapsed.components.attoseconds) / 1_000_000_000_000_000

            guard
                let http = response as? HTTPURLResponse,
                (200..<300).contains(http.statusCode),
                String(data: data, encoding: .utf8)?.contains("#EXTM3U") == true
            else {
                isReachable = false
                statusText = "الخادم ردّ لكن HLS playlist غير جاهز"
                latencyText = String(format: "%.0f ms", milliseconds)
                return
            }

            isReachable = true
            statusText = "Broadcast HLS server متصل"
            latencyText = String(format: "%.0f ms", milliseconds)
        } catch {
            isReachable = false
            statusText = "بانتظار Broadcast Extension على المنفذ 8765"
            latencyText = "—"
        }
    }
}
