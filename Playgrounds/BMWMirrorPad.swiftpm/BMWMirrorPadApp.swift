import SwiftUI

@main
struct BMWMirrorPadApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                LiveCaptureTestView()
            }
        }
    }
}
