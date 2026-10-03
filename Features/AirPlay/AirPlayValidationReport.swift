import Foundation

enum AirPlayValidationReport {
    @MainActor
    static func make(
        captureManager: ScreenCaptureManager,
        playerManager: AirPlayVideoManager,
        validationManager: AirPlayValidationManager
    ) -> String {
        let timestamp = ISO8601DateFormatter().string(from: Date())

        return """
        BMW Mirror — External AirPlay Validation
        ========================================
        Timestamp: \(timestamp)

        Capture
        -------
        Active: \(captureManager.isCapturing ? "YES" : "NO")
        Mode: \(captureManager.captureMode.title)
        Status: \(captureManager.statusText)

        Live HLS
        --------
        Ready: \(captureManager.liveHLSReady ? "YES" : "NO")
        URL: \(captureManager.liveHLSPlaybackURL?.absoluteString ?? "—")
        First-ready latency: \(captureManager.liveHLSFirstReadyLatencyText)
        Segments: \(captureManager.liveHLSSegmentCount)
        Buffer bytes: \(captureManager.liveHLSBytes)
        HTTP requests: \(captureManager.liveHLSTotalRequests)
        Playlist requests: \(captureManager.liveHLSPlaylistRequests)
        Media requests: \(captureManager.liveHLSMediaRequests)
        Likely external-client requests: \(captureManager.liveHLSExternalClientRequests)
        Served bytes: \(captureManager.liveHLSServedBytes)
        Last client: \(captureManager.liveHLSLastClientEndpoint)
        Last request: \(captureManager.liveHLSLastRequestPath)

        AVPlayer / AirPlay
        ------------------
        Source: \(playerManager.currentSourceLabel)
        Player item: \(playerManager.playerItemStatusText)
        Playing: \(playerManager.isPlaying ? "YES" : "NO")
        Likely to keep up: \(playerManager.isPlaybackLikelyToKeepUp ? "YES" : "NO")
        Playback stalls: \(playerManager.playbackStallCount)
        External playback active: \(playerManager.isExternalPlaybackActive ? "YES" : "NO")
        External transition: \(playerManager.externalPlaybackTransitionText)

        Route / Network
        ---------------
        Route detector: \(validationManager.routeDetectionText)
        Multiple routes detected: \(validationManager.multipleRoutesDetected ? "YES" : "NO")
        Audio route: \(validationManager.currentAudioRouteText)
        Network path: \(validationManager.networkPathText)
        Interfaces: \(validationManager.networkInterfacesText)

        Validation
        ----------
        Strong success signal requires BOTH:
        1. AVPlayer.isExternalPlaybackActive == true
        2. External receiver requests are visible OR another verified receiver-side playback signal.

        This report does not by itself prove CarPlay Video support.
        """
    }
}
