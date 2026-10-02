# CarPlay Entitlement Request Plan

## App identity
- App name: BMW Mirror
- Bundle ID: `com.abdulstar.bmwmirror`
- Target: iPhone
- Vehicle target for testing: BMW X6 2025

## Candidate official category
The current candidate for the project's video goal is **CarPlay Video App**.

Entitlement example:

```text
com.apple.developer.carplay-video
```

## Scope warning
This entitlement is for the CarPlay Video application category. It is **not** a generic unrestricted iPhone-screen-mirroring entitlement.

The project must therefore have a real video implementation and AirPlay-capable playback/output path before the request is made.

## Why the entitlement is not active
`BMWMirror.entitlements.example` is deliberately not attached to the Xcode target. Adding an entitlement that is absent from the active provisioning profile would cause signing problems.

## Engineering gate before payment/request
Before enrolling or requesting the entitlement:

1. Complete the AirPlay Video output/playback layer.
2. Prove that the produced video media can use an AirPlay-capable playback path.
3. Keep diagnostics for route availability and playback state.
4. Keep the CarPlay UI and app description aligned with what the app actually does.

## After that gate passes
1. Enroll the Apple ID in Apple Developer Program.
2. Register/confirm App ID `com.abdulstar.bmwmirror`.
3. Request the applicable CarPlay Video entitlement.
4. Wait for Apple approval.
5. Generate a provisioning profile containing the approved entitlement.
6. Copy `BMWMirror.entitlements.example` to `BMWMirror.entitlements`.
7. Set `CODE_SIGN_ENTITLEMENTS = BMWMirrorApp/BMWMirror.entitlements`.
8. Build and inspect the signed entitlement.
9. Test the applicable CarPlay environment.
10. Verify support on the specific BMW X6 2025 head unit while parked.

## Current state
The repository is intentionally kept before the paid entitlement boundary until the AirPlay Video layer is implemented.
