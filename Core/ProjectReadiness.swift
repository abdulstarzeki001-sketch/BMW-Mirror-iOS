import Foundation

struct ReadinessItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let isReady: Bool
}

enum ProjectReadiness {
    static let items: [ReadinessItem] = [
        .init(
            title: "Xcode Project",
            detail: "BMWMirror.xcodeproj موجود ومجهز للبناء",
            isReady: true
        ),
        .init(
            title: "Screen Capture",
            detail: "ReplayKit capture + live preview",
            isReady: true
        ),
        .init(
            title: "Media Pipeline",
            detail: "30 FPS target + orientation + diagnostics",
            isReady: true
        ),
        .init(
            title: "CarPlay Scene",
            detail: "CPTemplateApplicationScene + scene delegate",
            isReady: true
        ),
        .init(
            title: "CarPlay Entitlement",
            detail: "بانتظار موافقة Apple والتوقيع",
            isReady: false
        ),
        .init(
            title: "BMW X6 Physical Test",
            detail: "بانتظار entitlement-enabled build",
            isReady: false
        )
    ]

    static var completedCount: Int {
        items.filter(\.isReady).count
    }

    static var totalCount: Int {
        items.count
    }

    static var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
}
