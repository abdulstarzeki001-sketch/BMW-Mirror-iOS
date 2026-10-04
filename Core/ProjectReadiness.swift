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
                detail: "Broadcast Upload Extension + fixed-port HLS bridge تم بناؤهما",
                isReady: true
            ),
            .init(
                id: "legacy-full-display-device-test",
                title: "Legacy Broadcast Device Test",
                detail: "يحتاج تجربة فعلية على iPhone لأن ReplayKit system broadcast لا يُثبت داخل Simulator",
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
                id: "airplay-probe",
                title: "AirPlay Playback Probe",
                detail: "AVPlayer + AVRoutePickerView + External Playback جاهز للاختبار",
                isReady: true
            ),
            .init(
                id: "live-hls-bridge",
                title: "Live Capture → HLS Bridge",
                detail: "AVAssetWriter ينتج fragmented MP4/HLS وخادم HTTP محلي يقدمه لـ AVPlayer",
                isReady: true
            ),
            .init(
                id: "airplay-validation-toolkit",
                title: "AirPlay Validation Toolkit",
                detail: "Route detection + network monitor + HTTP client metrics + stall tracking + shareable report",
                isReady: true
            ),
            .init(
                id: "device-validation-center",
                title: "Device Validation Center",
                detail: "يفحص الجهاز/الـappex/مسار الالتقاط/الشبكة/HLS ويصدر تقريرًا قبل entitlement",
                isReady: true
            ),
            .init(
                id: "device-signing-prep",
                title: "Physical Device Signing Prep",
                detail: "device-build.sh جاهز ويمنع تفعيل entitlement الحقيقي قبل موافقة Apple",
                isReady: true
            ),
            .init(
                id: "ipad-playgrounds-harness",
                title: "iPad Swift Playgrounds Harness",
                detail: "BMWMirrorPad.swiftpm جاهز لاختبار HLS/AirPlay/network diagnostics على iPad",
                isReady: true
            ),
            .init(
                id: "ipad-airplay-device-test",
                title: "iPad AirPlay Device Test",
                detail: "نجح Apple HLS Probe فعليًا عبر AirPlay إلى EShare-7866 مع External Playback نشط",
                isReady: true
            ),
            .init(
                id: "ipad-live-capture-airplay",
                title: "iPad Live Capture → AirPlay",
                detail: "ReplayKit in-app capture + H.264/HLS + local server + AVPlayer/AirPlay جاهز للاختبار الفعلي",
                isReady: false
            ),
            .init(
                id: "external-live-airplay",
                title: "Live HLS → External AirPlay",
                detail: "AirPlay الخارجي ثبت مع Apple HLS؛ المتبقي إثبات Local Live HLS القادم من الالتقاط الحي",
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
