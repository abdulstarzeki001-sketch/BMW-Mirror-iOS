# Stage 5 — CarPlay Scene & Simulator Preparation

Status: **Implementation complete; simulator visibility depends on an approved CarPlay entitlement.**

## Implemented
- Added `CarPlaySceneDelegate` conforming to `CPTemplateApplicationSceneDelegate`.
- Added a CarPlay scene manifest to `BMWMirrorApp/Info.plist`.
- Configured the CarPlay scene class as `CPTemplateApplicationScene`.
- Configured the scene delegate as `$(PRODUCT_MODULE_NAME).CarPlaySceneDelegate`.
- Added a safe `CPListTemplate` root UI for CarPlay.
- Added the CarPlay delegate and Info.plist to the Xcode project.
- Switched the target from a generated Info.plist to the checked-in Info.plist.

## CarPlay UI
The first CarPlay screen is intentionally simple and template-based:
- BMW Mirror
- Media Pipeline status
- Screen Capture status
- BMW X6 2025 target vehicle

This stage does **not** draw arbitrary SwiftUI/video content directly into the CarPlay window. Apple permits non-navigation apps to construct their CarPlay UI through `CPInterfaceController` and CarPlay templates.

## Simulator
The project is now structurally prepared for Apple’s CarPlay Simulator. Actual app visibility/launch in CarPlay still depends on the applicable CarPlay entitlement on the signing profile.

## Next
Stage 6 — identify and prepare the correct CarPlay entitlement/capability path for the intended video/mirroring use case, without paying until the rest of the project is ready.
