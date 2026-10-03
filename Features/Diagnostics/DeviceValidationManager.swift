import Foundation
import UIKit

struct DeviceValidationCheck: Identifiable {
    let id: String
    let title: String
    let detail: String
    let passed: Bool
}

@MainActor
final class DeviceValidationManager: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var checks: [DeviceValidationCheck] = []
    @Published private(set) var summaryText = "لم يبدأ الفحص"
    @Published private(set) var lastRunText = "—"

    var isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    var environmentText: String {
        isSimulator ? "iOS Simulator" : "Physical iPhone"
    }

    var systemVersionText: String {
        "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    }

    var modernFullDisplayExpected: Bool {
        if #available(iOS 27.0, *) {
            return true
        }
        return false
    }

    var preferredCapturePathText: String {
        modernFullDisplayExpected
            ? "ScreenCaptureKit full display"
            : "ReplayKit Broadcast Upload Extension"
    }

    func run(
        captureManager: ScreenCaptureManager,
        carPlayManager: CarPlayManager
    ) async {
        guard !isRunning else { return }

        isRunning = true
        summaryText = "جارٍ الفحص…"

        var results: [DeviceValidationCheck] = []

        results.append(
            DeviceValidationCheck(
                id: "physical-device",
                title: "Physical iPhone",
                detail: isSimulator
                    ? "الاختبار النهائي يحتاج iPhone فعلي."
                    : "التطبيق يعمل على جهاز iPhone فعلي.",
                passed: !isSimulator
            )
        )

        let extensionEmbedded = Self.broadcastExtensionIsEmbedded()
        results.append(
            DeviceValidationCheck(
                id: "broadcast-extension",
                title: "Broadcast Extension Embedded",
                detail: extensionEmbedded
                    ? "BMWMirrorBroadcast.appex موجود داخل التطبيق."
                    : "لم يتم العثور على BMWMirrorBroadcast.appex داخل التطبيق الجاري.",
                passed: extensionEmbedded
            )
        )

        results.append(
            DeviceValidationCheck(
                id: "capture-api",
                title: "Capture Path",
                detail: preferredCapturePathText,
                passed: modernFullDisplayExpected
                    ? captureManager.supportsFullDisplayCapture
                    : extensionEmbedded
            )
        )

        let networkAddress = LiveHLSHTTPServer.preferredLocalIPv4Address()
        results.append(
            DeviceValidationCheck(
                id: "local-ipv4",
                title: "Local Network Address",
                detail: networkAddress ?? "لا يوجد IPv4 محلي قابل للاستخدام الآن.",
                passed: networkAddress != nil
            )
        )

        results.append(
            DeviceValidationCheck(
                id: "carplay-scene",
                title: "CarPlay App Scene",
                detail: carPlayManager.isConnected
                    ? "BMW Mirror لديه مشهد CarPlay نشط."
                    : "لا يوجد مشهد CarPlay نشط حاليًا؛ هذا طبيعي خارج السيارة/Simulator.",
                passed: carPlayManager.isConnected
            )
        )

        if let url = captureManager.liveHLSPlaybackURL {
            let reachable = await Self.probeHLS(url: url)
            results.append(
                DeviceValidationCheck(
                    id: "live-hls",
                    title: "Live HLS Reachability",
                    detail: reachable
                        ? "live.m3u8 استجاب كـ HLS."
                        : "Live HLS URL موجود لكنه لم يستجب كـ HLS.",
                    passed: reachable
                )
            )
        } else {
            results.append(
                DeviceValidationCheck(
                    id: "live-hls",
                    title: "Live HLS Reachability",
                    detail: "ابدأ الالتقاط أولًا حتى يظهر live.m3u8.",
                    passed: false
                )
            )
        }

        checks = results
        let passedCount = results.filter(\.passed).count
        summaryText = "\(passedCount)/\(results.count) checks passed"
        lastRunText = Self.clockText()
        isRunning = false
    }

    func makeReport(
        captureManager: ScreenCaptureManager,
        carPlayManager: CarPlayManager
    ) -> String {
        let checkLines = checks
            .map { check in
                "[\(check.passed ? "PASS" : "WAIT")] \(check.title): \(check.detail)"
            }
            .joined(separator: "\n")

        return """
        BMW Mirror — Device Validation Center
        =====================================
        Timestamp: \(ISO8601DateFormatter().string(from: Date()))
        Environment: \(environmentText)
        Device: \(UIDevice.current.model)
        System: \(systemVersionText)
        Preferred capture path: \(preferredCapturePathText)

        Self-test
        ---------
        \(checkLines.isEmpty ? "No self-test run yet." : checkLines)

        Runtime
        -------
        CarPlay scene: \(carPlayManager.isConnected ? "CONNECTED" : "NOT CONNECTED")
        CarPlay status: \(carPlayManager.statusText)
        Capture active: \(captureManager.isCapturing ? "YES" : "NO")
        Capture mode: \(captureManager.captureMode.title)
        Capture status: \(captureManager.statusText)
        Live HLS ready: \(captureManager.liveHLSReady ? "YES" : "NO")
        Live HLS URL: \(captureManager.liveHLSPlaybackURL?.absoluteString ?? "—")
        HLS segments: \(captureManager.liveHLSSegmentCount)
        External-client requests: \(captureManager.liveHLSExternalClientRequests)

        Required next proof
        -------------------
        1. Run on a real iPhone.
        2. Start full-display capture for the current iOS version.
        3. Confirm Live HLS becomes ready.
        4. Confirm a real AirPlay receiver activates external playback.
        5. Only then proceed to CarPlay Video entitlement and BMW validation.
        """
    }

    private static func broadcastExtensionIsEmbedded() -> Bool {
        guard let pluginsURL = Bundle.main.builtInPlugInsURL else {
            return false
        }

        let extensionURL = pluginsURL
            .appendingPathComponent("BMWMirrorBroadcast.appex")

        return FileManager.default.fileExists(
            atPath: extensionURL.path
        )
    }

    private static func probeHLS(url: URL) async -> Bool {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 2

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard
                let http = response as? HTTPURLResponse,
                (200..<300).contains(http.statusCode),
                let playlist = String(data: data, encoding: .utf8)
            else {
                return false
            }

            return playlist.contains("#EXTM3U")
        } catch {
            return false
        }
    }

    private static func clockText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}
