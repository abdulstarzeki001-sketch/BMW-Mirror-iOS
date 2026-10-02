import Foundation

struct ReadinessItem: Identifiable {
    let id: String
    let title: String
    let detail: String
    let isReady: Bool
}

enum ProjectReadiness {
    static var items: [ReadinessItem] {
        [
            .init(
                id: "xcode-project",
                title: "Xcode Project",
                detail: "BMWMirror.xcodeproj يبني بنجاح في CI",
                isReady: true
            ),
            .init(
                id: "legacy-inapp-capture",
                title: "ReplayKit In-App Capture",
                detail: "جاهز كمسار توافق داخل BMW Mirror نفسه",
                isReady: true
            ),
            .init(
                id: "legacy-full-display-broadcast",
                title: "Legacy Full Display (iOS 17–26)",
                detail: "يحتاج ReplayKit Broadcast Upload Extension + نقل الإطارات إلى التطبيق",
                isReady: false
            ),
            .init(
                id: "modern-full-display-capture",
                title: "Full Display Capture (iOS 27+)",
                detail: "ScreenCaptureKit path موجود ويستخدم system content picker",
                isReady: true
            ),
            .init(
                id: "media-pipeline",
                title: "Media Pipeline",
                detail: "30 FPS target + orientation + diagnostics",
                isReady: true
            ),
            .init(
                id: "carplay-scene",
                title: "CarPlay Scene",
                detail: "CPTemplateApplicationScene + scene delegate",
                isReady: true
            ),
            .init(
                id: "airplay-video",
                title: "AirPlay Video Output",
                detail: "مطلوب لمسار CarPlay Video الرسمي ولم يتم تنفيذه بعد",
                isReady: false
            ),
            .init(
                id: "carplay-entitlement",
                title: "CarPlay Video Entitlement",
                detail: "بانتظار Apple Developer + موافقة Apple",
                isReady: false
            ),
            .init(
                id: "bmw-test",
                title: "BMW X6 Physical Test",
                detail: "بانتظار output path + entitlement-enabled build",
                isReady: false
            )
        ]
    }

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
