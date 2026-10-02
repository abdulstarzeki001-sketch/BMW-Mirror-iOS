import Foundation
import Combine
import UIKit

@MainActor
final class CarPlayManager: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var statusText = "غير متصل"
    @Published private(set) var lastEventText = "بانتظار إنشاء مشهد CarPlay الخاص بالتطبيق"

    private var cancellables = Set<AnyCancellable>()

    init() {
        observeCarPlaySceneLifecycle()
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

        center.publisher(for: UIScene.didConnectNotification)
            .merge(with: center.publisher(for: UIScene.didDisconnectNotification))
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                self?.handleSceneLifecycleNotification(notification)
            }
            .store(in: &cancellables)
    }

    private func handleSceneLifecycleNotification(_ notification: Notification) {
        guard
            let scene = notification.object as? UIScene,
            scene.session.role == .carTemplateApplication
        else {
            return
        }

        if notification.name == UIScene.didConnectNotification {
            applyConnectionState(
                true,
                eventText: "تم إنشاء مشهد CarPlay الخاص بـ BMW Mirror"
            )
        } else if notification.name == UIScene.didDisconnectNotification {
            applyConnectionState(
                false,
                eventText: "تم فصل مشهد CarPlay الخاص بـ BMW Mirror"
            )
        }
    }

    private func applyConnectionState(_ connected: Bool, eventText: String) {
        isConnected = connected
        statusText = connected ? "المشهد متصل" : "المشهد غير متصل"
        lastEventText = eventText
    }
}
