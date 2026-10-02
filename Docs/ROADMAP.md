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
- Downscale long edge to 1280 px
- Receive application-audio sample buffers
- Track frame drops, actual FPS, processing latency, source/output size and orientation

## ✅ Stage 5 — CarPlay Scene / Simulator Preparation
- Add `CPTemplateApplicationScene` configuration
- Add `CarPlaySceneDelegate`
- Set a safe `CPListTemplate` root screen
- Check in an explicit Info.plist with the CarPlay scene manifest
- Prepare the project structure for CarPlay Simulator
- Runtime CarPlay visibility remains gated by an approved entitlement

## ⏳ Stage 6 — Entitlements
- Determine the applicable CarPlay category for the intended experience
- Prepare identifiers and entitlement file
- Document Apple Developer Program requirements
- Request the applicable entitlement only when the project is otherwise ready

## Stage 7 — BMW X6 Test
- Install signed build
- Test wireless CarPlay connection
- Verify app visibility and supported presentation
- Record limitations and compatibility
