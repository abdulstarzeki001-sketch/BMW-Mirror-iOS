# Stage 6 — Entitlement Preparation

Status: **Preparation complete; activation intentionally deferred.**

## Completed
- Candidate entitlement documented: `com.apple.developer.carplay-video`.
- `BMWMirror.entitlements.example` added.
- The entitlement is intentionally not attached to signing.
- Bundle ID and provisioning steps are documented.

## Engineering blocker before requesting it
The project still needs a working **AirPlay Video output/playback path**.

The CarPlay Video entitlement is not a generic permission to draw arbitrary iPhone UI on the CarPlay display. Requesting it before the app has a truthful video/AirPlay implementation would put the project in the wrong order.

## Correct order
1. Complete AirPlay-capable video output.
2. Test the video path without CarPlay entitlement where possible.
3. Enroll in Apple Developer Program.
4. Request the applicable CarPlay Video entitlement.
5. After approval, create a provisioning profile containing the entitlement.
6. Attach the real entitlement file to the Xcode target.
7. Build and verify signed entitlements.
8. Test CarPlay/vehicle support.

No payment is needed for the repository work completed so far.
