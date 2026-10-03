import Foundation
import AVFoundation
import Network
import UIKit

@MainActor
final class PlaygroundDiagnostics: ObservableObject {
    @Published private(set) var routeDetectionText = "جارٍ الفحص"
    @Published private(set) var multipleRoutesDetected = false
    @Published private(set) var currentAudioRouteText = "—"
    @Published private(set) var networkPathText = "—"
    @Published private(set) var interfacesText = "—"
    @Published private(set) var lastProbeText = "لم يتم الفحص"
    @Published private(set) var lastProbeLatencyText = "—"
    @Published private(set) var lastProbeSucceeded = false

    private let routeDetector = AVRouteDetector()
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(
        label: "com.abdulstar.bmwmirror.pad-diagnostics"
    )

    private var timer: Timer?
    private var routeObserver: NSObjectProtocol?

    init() {
        routeDetector.isRouteDetectionEnabled = true

        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshAudioRoute()
            }
        }

        pathMonitor.pathUpdateHandler = { [weak self] path in
            let status: String
            switch path.status {
            case .satisfied:
                status = "satisfied"
            case .unsatisfied:
                status = "unsatisfied"
            case .requiresConnection:
                status = "requires connection"
            @unknown default:
                status = "unknown"
            }

            let interfaces = path.availableInterfaces
                .map { "\($0.type):\($0.name)" }
                .joined(separator: ", ")

            Task { @MainActor [weak self] in
                self?.networkPathText = status
                self?.interfacesText = interfaces.isEmpty ? "—" : interfaces
            }
        }

        pathMonitor.start(queue: monitorQueue)
        refreshAudioRoute()
        startPolling()
    }

    deinit {
        timer?.invalidate()
        pathMonitor.cancel()

        if let routeObserver {
            NotificationCenter.default.removeObserver(routeObserver)
        }

        routeDetector.isRouteDetectionEnabled = false
    }

    func probe(url: URL) async {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 4

        let started = ContinuousClock.now

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let elapsed = started.duration(to: .now)
            let milliseconds =
                Double(elapsed.components.seconds) * 1000 +
                Double(elapsed.components.attoseconds) / 1_000_000_000_000_000

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let looksLikeHLS =
                String(data: data.prefix(512), encoding: .utf8)?
                .contains("#EXTM3U") == true

            lastProbeSucceeded = (200..<300).contains(statusCode) && looksLikeHLS
            lastProbeLatencyText = String(format: "%.0f ms", milliseconds)
            lastProbeText = lastProbeSucceeded
                ? "HLS قابل للوصول"
                : "رد HTTP \(statusCode)، لكن المحتوى ليس HLS صالحًا"
        } catch {
            lastProbeSucceeded = false
            lastProbeLatencyText = "—"
            lastProbeText = error.localizedDescription
        }
    }

    var deviceText: String {
        "\(UIDevice.current.model) • iPadOS/iOS \(UIDevice.current.systemVersion)"
    }

    func makeReport(player: PlaygroundAirPlayPlayer, customURL: String) -> String {
        """
        BMW Mirror Pad — iPad Validation Report
        =======================================
        Time: \(ISO8601DateFormatter().string(from: Date()))

        Device
        ------
        \(deviceText)

        Network
        -------
        Path: \(networkPathText)
        Interfaces: \(interfacesText)
        Route detector: \(routeDetectionText)
        Multiple routes: \(multipleRoutesDetected ? "YES" : "NO")
        Audio route: \(currentAudioRouteText)

        HLS Probe
        ---------
        URL: \(customURL.isEmpty ? "Apple HLS Probe" : customURL)
        Result: \(lastProbeText)
        Latency: \(lastProbeLatencyText)

        AVPlayer / AirPlay
        ------------------
        Source: \(player.sourceLabel)
        Player item: \(player.itemStatusText)
        Playing: \(player.isPlaying ? "YES" : "NO")
        Keep up: \(player.isPlaybackLikelyToKeepUp ? "YES" : "NO")
        Stalls: \(player.playbackStallCount)
        External playback: \(player.isExternalPlaybackActive ? "YES" : "NO")
        External transition: \(player.externalTransitionText)

        Note
        ----
        This iPad harness validates HLS playback, network reachability and AirPlay behavior.
        It does not validate ReplayKit Broadcast Upload Extension or CarPlay entitlements.
        """
    }

    private func startPolling() {
        timer?.invalidate()

        timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }

                self.multipleRoutesDetected = self.routeDetector.multipleRoutesDetected
                self.routeDetectionText = self.multipleRoutesDetected
                    ? "تم اكتشاف route إضافي"
                    : "لا يوجد route إضافي حاليًا"
            }
        }
    }

    private func refreshAudioRoute() {
        let outputs = AVAudioSession.sharedInstance()
            .currentRoute
            .outputs
            .map { "\($0.portName) [\($0.portType.rawValue)]" }

        currentAudioRouteText = outputs.isEmpty
            ? "لا يوجد output"
            : outputs.joined(separator: ", ")
    }
}
