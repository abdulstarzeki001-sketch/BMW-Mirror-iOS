# Stage 6 — Entitlement Preparation

Status: **Free preparation complete; Apple approval/payment intentionally deferred.**

## Completed without a paid membership
- Selected the current official CarPlay video entitlement candidate.
- Added `BMWMirror.entitlements.example`.
- Kept the entitlement disconnected from signing so free builds are not broken.
- Documented the exact bundle ID and activation steps.
- Documented the boundary between CarPlay video support and unrestricted screen mirroring.

## Pending external step
The next real CarPlay step requires:
- Apple Developer Program membership.
- Apple approval for the applicable CarPlay entitlement.
- A provisioning profile containing the approved entitlement.

No payment has been made or required by these repository changes.

## After approval
Attach the real entitlement file to the Xcode target, rebuild, run the CarPlay Simulator, then test in the BMW X6 2025.
