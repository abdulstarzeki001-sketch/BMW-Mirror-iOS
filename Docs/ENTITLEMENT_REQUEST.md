# CarPlay Entitlement Request Plan

## App identity
- App name: BMW Mirror
- Bundle ID: `com.abdulstar.bmwmirror`
- Target: iPhone
- Vehicle target: BMW X6 2025

## Intended official CarPlay category
The closest current public CarPlay category to the project’s media goal is **CarPlay Video App**.

Entitlement key:

```text
com.apple.developer.carplay-video
```

## Important limitation
This entitlement is for **video apps**, not a generic permission to mirror arbitrary iPhone UI.

Apple’s current CarPlay video-app path is intended for supported vehicles when parked. It also expects the app to support AirPlay video streaming.

Therefore the request to Apple must describe the app truthfully as a video/media experience. We should not claim that the entitlement guarantees unrestricted full-screen mirroring of all apps.

## Why the entitlement file is not active yet
`BMWMirror.entitlements.example` is intentionally not attached to the Xcode target.

If we add an entitlement that is absent from the active provisioning profile, device signing will fail.

## When ready to pay/request
1. Enroll the Apple ID in Apple Developer Program.
2. Register or confirm App ID `com.abdulstar.bmwmirror`.
3. Request the applicable CarPlay entitlement from Apple.
4. Wait for approval.
5. Regenerate/download the provisioning profile containing that entitlement.
6. Copy `BMWMirror.entitlements.example` to `BMWMirror.entitlements`.
7. Set `CODE_SIGN_ENTITLEMENTS = BMWMirrorApp/BMWMirror.entitlements` in Debug/Release.
8. Build and verify the signed entitlement.
9. Test in CarPlay Simulator.
10. Test on the BMW X6 2025.

## Pre-payment state
Everything up to the entitlement approval boundary remains in the repository without requiring payment.
