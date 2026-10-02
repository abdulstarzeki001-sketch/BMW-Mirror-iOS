# Stage 3 — Screen Capture

Status: **Complete**

## Implemented
- Start/stop live screen capture using ReplayKit.
- Receive video frames as `CMSampleBuffer`.
- Convert captured pixel buffers to `CGImage`.
- Show a live preview inside BMW Mirror.
- Show frame count and captured resolution.
- Show capture status and runtime errors.
- Microphone capture is disabled for this first proof-of-capture stage.

## Compatibility decision
The project currently targets iOS 17+, so Stage 3 uses ReplayKit for the compatibility path.

Apple's newer ScreenCaptureKit replaces ReplayKit for screen streaming and mirroring on newer operating systems. The iOS full-display ScreenCaptureKit sample requires iOS 27 or later, so migration can be added later without dropping compatibility with older iOS versions.

## Scope
This stage proves that BMW Mirror can receive live screen frames while its app capture session is active. It does **not** yet send those frames to CarPlay and it does not claim unrestricted background capture of every app.

## Next
Stage 4 — Media Pipeline: frame throttling, orientation, audio, latency and a transport-ready stream.
