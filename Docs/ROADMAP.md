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

## ⏳ Stage 3 — Screen Capture
- Integrate the appropriate iOS screen capture API
- Start/stop capture
- Preview captured frames inside the iPhone app

## Stage 4 — Media Pipeline
- Frame pipeline
- Orientation handling
- Audio path
- Latency measurements

## Stage 5 — CarPlay Simulator
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
