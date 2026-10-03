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

        CarPlay App Scene
        -----------------
        Scene Connected: \(carPlayManager.isConnected ? "YES" : "NO")
        Status: \(carPlayManager.statusText)
        Last Event: \(carPlayManager.lastEventText)

        Screen Capture
        --------------
        Mode: \(captureManager.captureMode.title)
        Mode Detail: \(captureManager.captureMode.detail)
        Full Display Supported: \(captureManager.supportsFullDisplayCapture ? "YES" : "NO")
        Capturing: \(captureManager.isCapturing ? "YES" : "NO")
        Busy: \(captureManager.isBusy ? "YES" : "NO")
        Status: \(captureManager.statusText)

        Media Pipeline
        --------------
        Target FPS: \(captureManager.targetFPS)
        Actual FPS: \(captureManager.actualFPSText)
        Processing Latency: \(captureManager.processingLatencyText)
        Source Size: \(captureManager.sourceSizeText)
        Output Size: \(captureManager.frameSizeText)
        Orientation: \(captureManager.orientationText)
        Processed Frames: \(captureManager.frameCount)
        Throttled Frames: \(captureManager.droppedFrameCount)
        Failed Frames: \(captureManager.failedFrameCount)
        Audio Packets: \(captureManager.audioPacketCount)

        CarPlay Video Path
        ------------------
        Entitlement Example: com.apple.developer.carplay-video
        Entitlement Attached To Signing: NO (intentionally deferred)
        AirPlay Probe Path: IMPLEMENTED
        Live HLS Bridge: \(captureManager.liveHLSReady ? "READY" : "NOT READY")
        Live HLS Segments: \(captureManager.liveHLSSegmentCount)
        Live HLS Bytes: \(captureManager.liveHLSBytes)
        Live HLS URL: \(captureManager.liveHLSPlaybackURL?.absoluteString ?? "—")
        First-ready latency: \(captureManager.liveHLSFirstReadyLatencyText)
        HLS HTTP requests: \(captureManager.liveHLSTotalRequests)
        HLS playlist requests: \(captureManager.liveHLSPlaylistRequests)
        HLS media requests: \(captureManager.liveHLSMediaRequests)
        HLS likely-external requests: \(captureManager.liveHLSExternalClientRequests)
        HLS served bytes: \(captureManager.liveHLSServedBytes)
        HLS last client: \(captureManager.liveHLSLastClientEndpoint)
        HLS last path: \(captureManager.liveHLSLastRequestPath)
        External Live AirPlay Validation: TOOLKIT READY / DEVICE TEST NOT RUN
        Modern Full-Display Path: iOS 27+ ScreenCaptureKit
        Legacy Full-Display Path: ReplayKit Broadcast Upload Extension
        Legacy Broadcast Port: \(AppConstants.legacyBroadcastPort)
        Legacy Extension Bundle ID: \(AppConstants.legacyBroadcastExtensionBundleID)

        BMW Physical Test
        -----------------
        Status: NOT RUN
        """
    }
}
