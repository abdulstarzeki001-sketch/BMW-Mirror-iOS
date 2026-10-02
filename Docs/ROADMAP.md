# BMW Mirror Roadmap

## ✅ Stage 1 — Project Skeleton
- Buildable Xcode project
- Shared scheme
- SwiftUI app entry point
- Home screen
- CarPlay status placeholder
- Screen capture status placeholder
- Base folder structure
- GitHub Actions simulator build validation

## ✅ Stage 2 — CarPlay Detection
- Observe CarPlay scene connect/disconnect lifecycle
- Detect `UISceneSession.Role.carTemplateApplication`
- Reflect live connection state in the iPhone UI
- Refresh state when the iPhone app becomes active
- Manual refresh button and connection event text

## ✅ Stage 3 — Screen Capture
- Integrate ReplayKit capture for the iOS 17+ compatibility path
- Start/stop capture from the app
- Convert video sample buffers into preview frames
- Show live frame preview, frame count, resolution, status, and errors

## ✅ Stage 4 — Media Pipeline
- Separate capture from media processing
- Correct ReplayKit frame orientation
- Throttle video to a 30 FPS target
- Downscale long edge to 1280 px for a lighter transport stream
- Receive application-audio sample buffers
- Track frame drops, actual FPS, processing latency, source/output size and orientation
- Expose a transport-friendly processed-frame boundary for the next CarPlay stage

## ⏳ Stage 5 — CarPlay Simulator
- Add supported CarPlay scene configuration
- Test behavior in Apple CarPlay Simulator
- Verify supported template/scene behavior

## Stage 6 — Entitlements
- Prepare required identifiers and capability configuration
- Document Apple Developer Program requirements
- Request applicable CarPlay entitlement

## Stage 7 — BMW X6 Test
- Install signed build
- Test wireless CarPlay connection
- Verify app visibility and supported presentation
- Record limitations and compatibility
