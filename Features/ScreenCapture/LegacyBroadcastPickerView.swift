import SwiftUI
import ReplayKit

struct LegacyBroadcastPickerView: UIViewRepresentable {
    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let picker = RPSystemBroadcastPickerView(frame: .zero)
        picker.preferredExtension = AppConstants.legacyBroadcastExtensionBundleID
        picker.showsMicrophoneButton = false
        return picker
    }

    func updateUIView(
        _ uiView: RPSystemBroadcastPickerView,
        context: Context
    ) {
        uiView.preferredExtension = AppConstants.legacyBroadcastExtensionBundleID
        uiView.showsMicrophoneButton = false
    }
}
