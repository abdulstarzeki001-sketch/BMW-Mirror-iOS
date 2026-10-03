import ReplayKit
import Network

final class SampleHandler: RPBroadcastSampleHandler {
    private lazy var bridge: LiveCaptureAirPlayBridge = {
        let port = NWEndpoint.Port(
            rawValue: AppConstants.legacyBroadcastPort
        ) ?? .any

        let bridge = LiveCaptureAirPlayBridge(port: port)

        bridge.onError = { [weak self] error in
            self?.finishBroadcastWithError(error)
        }

        return bridge
    }()

    override func broadcastStarted(
        withSetupInfo setupInfo: [String: NSObject]?
    ) {
        bridge.start()
    }

    override func broadcastPaused() {
        // ReplayKit pauses sample delivery automatically.
    }

    override func broadcastResumed() {
        // Sample delivery resumes automatically.
    }

    override func broadcastFinished() {
        bridge.shutdown()
    }

    override func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        with sampleBufferType: RPSampleBufferType
    ) {
        guard sampleBuffer.isValid else { return }

        switch sampleBufferType {
        case .video:
            bridge.appendVideo(sampleBuffer)

        case .audioApp:
            bridge.appendAudio(sampleBuffer)

        case .audioMic:
            break

        @unknown default:
            break
        }
    }
}
