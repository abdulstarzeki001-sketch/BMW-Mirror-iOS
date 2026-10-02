import Foundation

enum CaptureMode: String, CaseIterable, Identifiable {
    case fullDisplay
    case inAppLegacy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fullDisplay:
            return "الشاشة كاملة"
        case .inAppLegacy:
            return "داخل التطبيق"
        }
    }

    var detail: String {
        switch self {
        case .fullDisplay:
            return "ScreenCaptureKit — iOS 27+"
        case .inAppLegacy:
            return "ReplayKit — توافق قديم"
        }
    }
}
