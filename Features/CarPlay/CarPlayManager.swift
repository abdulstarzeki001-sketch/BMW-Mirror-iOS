import Foundation
import Combine
import UIKit

extension Notification.Name {
    static let bmwMirrorCarPlaySceneDidConnect = Notification.Name(
        "BMWMirror.CarPlaySceneDidConnect"
    )

    static let bmwMirrorCarPlaySceneDidDisconnect = Notification.Name(
        "BMWMirror.CarPlaySceneDidDisconnect"
    )
}

@MainActor
final class CarPlayManager: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var statusText = "غير متصل"
    @Published private(set) var lastEventText = "بانتظار إنشاء مشهد CarPlay الخاص بالتطبيق"

    private var cancellables = Set<AnyCancellable>()

    init() {
        observeCarPlaySceneLifecycle()
        observeAppActivation()
        refreshConnectionState()
    }

    func refreshConnectionState() {
        let connected = UIApplication.shared.connectedScenes.contains { scene in
            scene.session.role == .carTemplateApplication
        }

        applyConnectionState(
            connected,
            eventText: connected
                ? "يوجد مشهد CarPlay نشط لـ BMW Mirror"
                : "لا يوجد مشهد CarPlay نشط لـ BMW Mirror"
        )
    }

    private func observeCarPlaySceneLifecycle() {
        let center = NotificationCenter.default

        center.publisher(for: .bmwMirrorCarPlaySceneDidConnect)
            .merge(with: center.publisher(for: .bmwMirrorCarPlaySceneDidDisconnect))
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self else { return }

                if notification.name == .bmwMirrorCarPlaySceneDidConnect {
                    self.applyConnectionState(
                        true,
                        eventText: "تم إنشاء مشهد CarPlay الخاص بـ BMW Mirror"
                    )
                } else {
                    self.applyConnectionState(
                        false,
                        eventText: "تم فصل مشهد CarPlay الخاص بـ BMW Mirror"
                    )
                }
            }
            .store(in: &cancellables)
    }

    private func observeAppActivation() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshConnectionState()
            }
            .store(in: &cancellables)
    }

    private func applyConnectionState(_ connected: Bool, eventText: String) {
        isConnected = connected
        statusText = connected ? "المشهد متصل" : "المشهد غير متصل"
        lastEventText = eventText
    }
}
