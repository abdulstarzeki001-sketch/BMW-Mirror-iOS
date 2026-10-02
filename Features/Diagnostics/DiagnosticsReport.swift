import Foundation
import UIKit

enum DiagnosticsReport {
    @MainActor
    static func make(
        carPlayManager: CarPlayManager,
        captureManager: ScreenCaptureManager
    ) -> String {
        let device = UIDevice.current
        let timestamp = ISO8601DateFormatter().string(from: Date())

        return """
        BMW Mirror Diagnostics
        ======================
        Timestamp: \(timestamp)
        Device: \(device.model)
        System: \(device.systemName) \(device.systemVersion)
        App: \(AppConstants.appName)
        Target Vehicle: \(AppConstants.targetVehicle)

        CarPlay
        -------
        Connected: \(carPlayManager.isConnected ? "YES" : "NO")
        Status: \(carPlayManager.statusText)
        Last Event: \(carPlayManager.lastEventText)

        Capture / Media Pipeline
        ------------------------
        Capturing: \(captureManager.isCapturing ? "YES" : "NO")
        Status: \(captureManager.statusText)
        Target FPS: \(captureManager.targetFPS)
        Actual FPS: \(captureManager.actualFPSText)
        Processing Latency: \(captureManager.processingLatencyText)
        Source Size: \(captureManager.sourceSizeText)
        Output Size: \(captureManager.frameSizeText)
        Orientation: \(captureManager.orientationText)
        Processed Frames: \(captureManager.frameCount)
        Dropped Frames: \(captureManager.droppedFrameCount)
        App Audio Packets: \(captureManager.audioPacketCount)

        CarPlay Entitlement
        -------------------
        Approved/activated in this repository: NO
        Candidate: com.apple.developer.carplay-video

        BMW Physical Test
        -----------------
        Status: NOT RUN
        """
    }
}
