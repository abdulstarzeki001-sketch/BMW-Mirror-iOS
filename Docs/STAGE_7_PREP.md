# Stage 7 — BMW X6 Test Preparation

Status: **Preparation complete; physical vehicle test pending.**

## Added before the BMW test
- Entitlement-free CarPlay UI preview inside the iPhone app.
- A shareable diagnostics report containing:
  - iOS/device information
  - CarPlay connection state
  - capture state
  - target/actual FPS
  - processing latency
  - source/output resolution
  - orientation
  - processed/dropped frames
  - application-audio packet count
- A fixed physical-test checklist.

## Physical test checklist
1. Build a signed app after the applicable CarPlay entitlement is approved.
2. Install the signed build on the iPhone.
3. Confirm normal Wireless CarPlay works with the BMW X6 2025.
4. Open BMW Mirror on iPhone.
5. Check that the CarPlay scene is created.
6. Verify BMW Mirror appears in the permitted CarPlay interface.
7. Start the media pipeline while parked.
8. Record FPS, latency, frame drops and audio packet activity.
9. Use **مشاركة تقرير الفحص** and save/share the generated report.
10. Record whether the vehicle accepts the intended video presentation path.

## Pass criteria
- CarPlay scene connects.
- No signing/entitlement error.
- UI is visible through an Apple-permitted CarPlay surface.
- Media pipeline remains stable.
- No unsafe video presentation while the vehicle is moving.

## Pending
The actual BMW result cannot be recorded until the signed entitlement-enabled build is installed and tested in the vehicle.
