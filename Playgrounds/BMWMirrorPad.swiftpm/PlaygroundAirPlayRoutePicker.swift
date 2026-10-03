import SwiftUI
import AVKit

struct PlaygroundAirPlayRoutePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.prioritizesVideoDevices = true
        return picker
    }

    func updateUIView(
        _ uiView: AVRoutePickerView,
        context: Context
    ) {
        uiView.prioritizesVideoDevices = true
    }
}
