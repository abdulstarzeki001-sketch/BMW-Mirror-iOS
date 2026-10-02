import Foundation
import Combine

@MainActor
final class ScreenCaptureManager: ObservableObject {
    @Published private(set) var isCapturing = false

    func toggleCapture() {
        isCapturing.toggle()
    }
}
