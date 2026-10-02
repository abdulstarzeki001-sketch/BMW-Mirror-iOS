import Foundation
import Combine

@MainActor
final class CarPlayManager: ObservableObject {
    @Published private(set) var isConnected = false

    init() {
        refreshConnectionState()
    }

    func refreshConnectionState() {
        // Stage 1 placeholder.
        // Real CarPlay scene/session detection will be added in Stage 2.
        isConnected = false
    }
}
