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
                detail: "BMWMirror.xcodeproj موجود ومجهز للبناء",
                isReady: true
            ),
            .init(
                id: "legacy-capture",
                title: "ReplayKit In-App Capture",
                detail: "جاهز كمسار توافق، لكنه لا يلتقط تطبيقات iPhone الأخرى",
                isReady: true
            ),
            .init(
                id: "full-display-capture",
                title: "Full Display Capture",
                detail: "ScreenCaptureKit path موجود؛ التشغيل الكامل يحتاج iOS 27+",
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
