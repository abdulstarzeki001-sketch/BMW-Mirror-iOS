# Stage 3 — Screen Capture

Status: **Complete as capture foundation.**

## Implemented
- ReplayKit compatibility capture for BMW Mirror's own app content.
- Start/stop capture with transition-state protection.
- Live frame preview, status and error reporting.
- iOS 27+ full-display capture path using ScreenCaptureKit.
- System content picker for the full-display path.
- `UIBackgroundModes = screen-capture` for the iOS 27+ full-display path.

## Important distinction
The ReplayKit path is **not** full iPhone screen mirroring across arbitrary apps. It is kept as an older compatibility/in-app capture path.

The full-display path is implemented separately with ScreenCaptureKit and is available only when the SDK/runtime supports the iOS 27+ APIs.

## Still missing
Captured full-display frames are not yet sent to CarPlay. A real AirPlay Video output/playback layer is still required before the project can test the official CarPlay Video path.

## Next
Media processing, then AirPlay Video output.
