# Stage 8 — Preflight & Readiness

Status: **Complete.**

## Added
- In-app Project Readiness screen.
- `Scripts/preflight.sh`.
- GitHub Actions Project Preflight workflow.
- Simulator build workflow.

## Preflight now checks
- Required project files.
- CarPlay scene role and scene delegate.
- `screen-capture` background mode.
- Deferred CarPlay Video entitlement example.
- No premature real entitlement attachment.
- Xcode source membership for core capture files.
- ReplayKit and ScreenCaptureKit wiring.
- Explicit AirPlay Video blocker in readiness.
- Plist parsing and key values.

## CI verification
After the audit:
- Project Preflight passed.
- The first simulator build exposed a real compile error in the old CarPlay scene-notification code.
- That code was replaced with explicit notifications posted by `CarPlaySceneDelegate`.
- The subsequent iOS Simulator build passed.

## Remaining blockers
Not all remaining work is external. The current order is:

1. **Internal:** implement AirPlay Video output/playback.
2. **External:** Apple Developer Program enrollment.
3. **External:** Apple approval for the applicable CarPlay entitlement.
4. **External/runtime:** entitlement-enabled provisioning/signing.
5. **Runtime:** verify BMW X6 2025 support and perform the physical test.
