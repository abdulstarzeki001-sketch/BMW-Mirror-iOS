# Stage 7 — BMW X6 2025 Test Preparation

Status: **Test tooling ready; physical test blocked by AirPlay output and entitlement.**

## Already prepared
- In-app CarPlay UI preview.
- Shareable diagnostics report.
- Capture mode and full-display-support reporting.
- FPS, latency, processed/throttled/failed frame metrics.
- BMW physical-test checklist.

## Prerequisites before the physical test
1. Complete a real AirPlay Video output/playback path.
2. Obtain the applicable Apple CarPlay entitlement.
3. Create a signed provisioning profile containing that entitlement.
4. Install the signed build on the iPhone.
5. Verify that the specific BMW X6 2025 head unit supports Apple's official Video in Car path.

## Physical test checklist
1. Confirm normal Wireless CarPlay works.
2. Open BMW Mirror on iPhone.
3. Confirm BMW Mirror's CarPlay app scene is created.
4. Verify the permitted CarPlay interface appears.
5. With the vehicle parked, test the supported video route.
6. Record route availability, FPS, latency, throttled/failed frames and audio activity.
7. Export **مشاركة تقرير الفحص**.
8. Confirm what happens when video playback becomes unavailable, including vehicle-motion restrictions.

## Pass criteria
- Valid signed entitlement.
- BMW Mirror CarPlay scene connects.
- The vehicle exposes the supported Video in Car route.
- The AirPlay/video path actually renders on the allowed vehicle display.
- Media pipeline remains stable.
- Video is not presented where the vehicle/CarPlay says playback is unavailable.

Until those conditions are met, the project should not be described as proven BMW screen mirroring.
