# BMW Mirror Roadmap

## ✅ Stage 1 — Project Skeleton
- Buildable Xcode project
- Shared scheme
- SwiftUI app entry point
- GitHub Actions build validation

## ✅ Stage 2 — CarPlay App-Scene Detection
- Observe CarPlay scene connect/disconnect lifecycle
- Detect `UISceneSession.Role.carTemplateApplication`
- Report app-scene status without pretending it is global CarPlay connection status

## ✅ Stage 3 — Capture Foundation
- ReplayKit compatibility path for in-app capture
- Explicitly label ReplayKit as app-only capture
- Add iOS 27+ ScreenCaptureKit full-display path
- Add `screen-capture` background mode

## ✅ Stage 4 — Media Pipeline
- Frame throttling
- Orientation handling
- 1280px transport preview
- App/system audio sample metrics
- Correct processed/throttled/failed frame accounting

## ✅ Stage 5 — CarPlay Scene
- `CPTemplateApplicationScene`
- `CarPlaySceneDelegate`
- Root `CPListTemplate`
- Explicit Info.plist scene manifest

## 🟡 Next — AirPlay Video Output
- Build a real video playback/output path that supports AirPlay
- Bridge captured/encoded content into a format AirPlay/CarPlay Video can play
- Verify route selection and external playback behavior
- Do not claim CarPlay mirroring until this path works

## 🟡 Stage 6 — CarPlay Video Entitlement
- Candidate: `com.apple.developer.carplay-video`
- Example entitlement file exists but is intentionally not attached
- Apple Developer Program enrollment pending
- Apple entitlement approval pending
- Provisioning profile with entitlement pending

## 🟡 Stage 7 — BMW X6 2025 Test
- Diagnostics and test checklist are ready
- Physical test waits for a working AirPlay Video path and signed entitlement-enabled build
- Vehicle support for the official Video in Car path must be verified

## ✅ Stage 8 — Preflight & Readiness
- Repository sanity checks
- Plist validation
- Xcode source-membership checks
- CI simulator build
- Honest readiness status for unresolved blockers
