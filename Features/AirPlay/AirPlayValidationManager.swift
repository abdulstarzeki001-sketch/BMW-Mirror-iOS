import Foundation
import AVFoundation
import Network

@MainActor
final class AirPlayValidationManager: ObservableObject {
    @Published private(set) var routeDetectionText = "جارٍ الفحص"
    @Published private(set) var multipleRoutesDetected = false
    @Published private(set) var currentAudioRouteText = "—"
    @Published private(set) var networkPathText = "—"
    @Published private(set) var networkInterfacesText = "—"

    private let routeDetector = AVRouteDetector()
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(
        label: "com.abdulstar.bmwmirror.airplay-validation"
    )

    private var timer: Timer?
    private var routeChangeObserver: NSObjectProtocol?

    init() {
        routeDetector.isRouteDetectionEnabled = true

        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshAudioRoute()
            }
        }

        pathMonitor.pathUpdateHandler = { [weak self] path in
            let pathText: String
            switch path.status {
            case .satisfied:
                pathText = "satisfied"
            case .unsatisfied:
                pathText = "unsatisfied"
            case .requiresConnection:
                pathText = "requires connection"
            @unknown default:
                pathText = "unknown"
            }

            let interfaces = path.availableInterfaces
                .map { "\($0.type):\($0.name)" }
                .joined(separator: ", ")

            Task { @MainActor [weak self] in
                self?.networkPathText = pathText
                self?.networkInterfacesText = interfaces.isEmpty ? "—" : interfaces
            }
        }

        pathMonitor.start(queue: monitorQueue)
        refreshAudioRoute()
        startPollingRouteDetector()
    }

    deinit {
        timer?.invalidate()
        pathMonitor.cancel()

        if let routeChangeObserver {
            NotificationCenter.default.removeObserver(routeChangeObserver)
        }

        routeDetector.isRouteDetectionEnabled = false
    }

    private func startPollingRouteDetector() {
        timer?.invalidate()

        timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }

                self.multipleRoutesDetected = self.routeDetector.multipleRoutesDetected
                self.routeDetectionText = self.multipleRoutesDetected
                    ? "تم اكتشاف أكثر من route"
                    : "لم يتم اكتشاف route إضافي"
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
