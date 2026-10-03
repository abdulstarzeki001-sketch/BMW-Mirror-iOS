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

## 🟡 Stage 3B — Full Display Compatibility for iOS 17–26
- Add ReplayKit Broadcast Upload Extension
- Start it through `RPSystemBroadcastPickerView`
- Receive video/audio `CMSampleBuffer` in `RPBroadcastSampleHandler`
- Transport frames from the extension to BMW Mirror
- This is a legacy/deprecated compatibility path

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

## 🟡 Stage 10B — External AirPlay Validation
- Verify that a real AirPlay receiver can reach the iPhone's live HLS server
- Measure end-to-end latency and stability
- Handle route/network changes
- If receiver-side fetching cannot reach the local server, replace the transport with an AirPlay-compatible delivery design
- Do not claim CarPlay mirroring until this validation succeeds

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
