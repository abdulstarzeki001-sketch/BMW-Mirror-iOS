# BMW Mirror Roadmap

## ✅ Stage 1 — Project Skeleton
- Buildable Xcode project
- Shared scheme
- SwiftUI app entry point
- GitHub Actions build validation

## ✅ Stage 2 — CarPlay App-Scene Detection
- Detect BMW Mirror's `UISceneSession.Role.carTemplateApplication` scene
- Publish scene connect/disconnect from `CarPlaySceneDelegate`
- Avoid presenting app-scene state as global CarPlay connection state

## ✅ Stage 3A — In-App Capture Compatibility
- ReplayKit `RPScreenRecorder` path
- Explicitly limited to BMW Mirror's own app content

## ✅ Stage 3B — Full Display Compatibility for iOS 17–26
- Added ReplayKit Broadcast Upload Extension target
- Added `RPSystemBroadcastPickerView` with preferred extension ID
- Added `RPBroadcastSampleHandler`
- Added required `RPBroadcastProcessModeSampleBuffer`
- Broadcast extension feeds video/audio directly into the HLS encoder
- Extension serves HLS on fixed port 8765
- Main app can derive the iPhone LAN URL and load it through AVPlayer/AirPlay
- No App Group is required for the media transport

## 🟡 Stage 3B Device Validation
- Start a real system broadcast on iPhone
- Verify the upload extension launches and stays alive
- Verify HLS appears on port 8765
- Verify AVPlayer loads the extension-generated stream
- Verify AirPlay external playback from the legacy path

## ✅ Stage 3C — Full Display Capture for iOS 27+
- ScreenCaptureKit
- `SCContentSharingPicker`
- `screen-capture` background mode

## ✅ Stage 4 — Media Pipeline
- Frame throttling
- Orientation handling
- 1280px preview/transport boundary
- Audio metrics
- Correct processed/throttled/failed frame accounting

## ✅ Stage 5 — CarPlay Scene
- `CPTemplateApplicationScene`
- `CarPlaySceneDelegate`
- Root `CPListTemplate`
- Explicit Info.plist scene manifest

## ✅ Stage 5B — AirPlay Playback Probe
- AVPlayer configured with `allowsExternalPlayback = true`
- Video-prioritized `AVRoutePickerView`
- External playback state monitoring
- Apple-hosted HLS probe stream
- In-app AirPlay test screen

## ✅ Stage 10A — Live Capture → HLS Bridge
- Feed accepted live video/audio sample buffers into AVAssetWriter
- Use `outputFileTypeProfile = .mpeg4AppleHLS`
- Emit fragmented MP4 initialization/media segments
- Maintain a rolling HLS playlist in memory
- Serve playlist/segments through a local Network.framework HTTP server
- Load the live HLS URL into AVPlayer
- Expose an AirPlay route picker on the live bridge screen

## ✅ Stage 10B — External AirPlay Validation Toolkit
- Instrument HLS server request/client metrics
- Count playlist/media/external-client requests
- Measure first-HLS-ready latency
- Monitor AVPlayer stalls and keep-up state
- Track `isExternalPlaybackActive`
- Monitor AVRouteDetector + current audio route
- Monitor Network.framework path/interfaces
- Generate a shareable AirPlay validation report

## ✅ Stage 11A — Pre-Entitlement Device Validation Center
- Detect Simulator vs physical iPhone
- Verify embedded `BMWMirrorBroadcast.appex`
- Select the expected capture path for the running iOS version
- Check local IPv4 availability
- Probe current Live HLS playlist when available
- Surface CarPlay app-scene state without treating it as video proof
- Generate a shareable device validation report

## 🟡 Stage 11B — Physical iPhone Validation
- Run Device Validation Center on a real iPhone
- Confirm the embedded broadcast extension is discoverable at runtime
- Confirm full-display capture for the current iOS version
- Confirm Live HLS is reachable on-device
- Preserve the exported report for comparison with the AirPlay/BMW test

## ✅ Stage 12A — Physical Device Signing Preparation
- Added guarded `Scripts/device-build.sh`
- Uses automatic signing with a caller-supplied `DEVELOPMENT_TEAM`
- Builds the host app + embedded Broadcast Upload Extension for physical iOS
- Runs preflight before signing
- Refuses to build if the real CarPlay entitlement file is prematurely attached
- Stores no signing secrets in the repository

## 🟡 Stage 12B — Signed Physical iPhone Run
- Sign/install through Xcode on a real iPhone
- Run Device Validation Center
- Validate the embedded Broadcast Upload Extension at runtime
- Keep CarPlay Video entitlement disabled until Apple approval

## 🟡 Stage 10C — Physical External AirPlay Validation
- Run the validation toolkit against a real AirPlay video receiver
- Confirm `isExternalPlaybackActive == true`
- Confirm receiver-side HLS requests or equivalent verified playback evidence
- Measure stability and practical latency
- If the receiver cannot fetch the local HLS endpoint, replace the transport design before CarPlay testing

## 🟡 Stage 6 — CarPlay Video Entitlement
- Candidate: `com.apple.developer.carplay-video`
- Example entitlement exists but is intentionally not attached
- Apple Developer Program enrollment pending
- Apple entitlement approval pending
- Provisioning profile with entitlement pending

## 🟡 Stage 7 — BMW X6 2025 Test
- Diagnostics and checklist ready
- Physical test waits for working video output and a signed entitlement-enabled build
- Vehicle support for Apple's Video in Car feature must be verified

## ✅ Stage 8 — Audit / Preflight
- Project Preflight passed
- iOS Simulator Build passed after fixing the CarPlay scene lifecycle compile error
- CI warnings reviewed
- Checkout workflow updated to a Node 24-compatible action


## ✅ Stage 13A — iPad Swift Playgrounds Harness
- Standalone `BMWMirrorPad.swiftpm` app playground
- Runs on iPad/iPhone with iOS/iPadOS 17+
- Apple HLS probe
- Custom HLS URL input
- HLS reachability + latency probe
- AVPlayer external playback monitoring
- AirPlay video route picker
- Route/network diagnostics
- Shareable validation report

## ✅ Stage 13B — iPad Physical AirPlay Validation
- BMWMirrorPad opened successfully in Swift Playgrounds on physical iPad
- Apple HLS probe played locally
- AirPlay receiver `EShare-7866` was selected
- `External Playback = active`
- The Apple HLS video appeared on the external TV
- Network path remained satisfied

## ✅ Stage 13C — iPad Live Capture Test Harness
- Added ReplayKit in-app capture
- Added real-time H.264 / Apple HLS encoding
- Added rolling in-memory live playlist
- Added local Network.framework HTTP server
- Added automatic AVPlayer loading when HLS becomes ready
- Added external HLS request metrics
- Added animated on-screen capture target

## 🟡 Stage 13D — Physical Live Capture → AirPlay Validation
- Start Live Capture on the iPad
- Wait for HLS Ready
- Select `EShare-7866`
- Confirm the animated capture target appears on the TV
- Confirm `External Playback = active`
- Confirm `External HLS Requests > 0`
- Record stalls and first-ready latency


## 🟡 Stage 13E — Live HLS Segment Reliability
- Physical iPad test confirmed ReplayKit delivers thousands of video frames
- Initial live bridge stayed at 0 segments / 0 KB
- Manual one-second `flushSegment()` was added
- Physical follow-up still showed no segments while the app audio track remained silent
- Live transport is now intentionally video-only so an empty AAC input cannot block CMAF/HLS finalization
- `initialSegmentStartTime` is no longer set for manual `.indefinite` segmentation
- One-second keyframe duration is requested for cleaner segment boundaries
- Physical re-test pending


## 🟡 Stage 13F — Encoded HLS segmentation correction
- Physical iPad v3 exposed `Cannot start file writing`
- Apple documents that custom segmentation with `preferredOutputSegmentInterval = .indefinite` + `flushSegment()` is passthrough-only
- That mode cannot be used while AVAssetWriter is encoding raw ReplayKit frames
- Live HLS has been corrected to encoded interval segmentation:
  - positive 1-second `preferredOutputSegmentInterval`
  - numeric `initialSegmentStartTime`
  - H.264 encoding remains enabled
  - one-second keyframe interval remains requested
  - video-only transport remains for this validation
- Physical v4 re-test pending
