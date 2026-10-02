# Stage 4 — Media Pipeline

Status: **Complete**

## Video path
```text
ReplayKit CMSampleBuffer
        ↓
orientation normalization
        ↓
30 FPS throttle
        ↓
max 1280 px long edge
        ↓
CGImage preview / processed-frame boundary
```

## Audio path
Application-audio buffers are now received separately from video. The pipeline records packet and timing metadata. Microphone audio remains disabled.

## Diagnostics
The iPhone UI shows:
- actual processed FPS
- target FPS
- per-frame processing time
- source resolution
- output resolution
- orientation
- processed frames
- throttled/dropped frames
- application-audio packet count

## Architecture
`ScreenCaptureManager` now owns capture state only. `MediaPipeline` performs the media work. This gives Stage 5 a clean output boundary to connect to whatever CarPlay presentation path Apple permits.

## Current limitation
The ReplayKit capture path used here is the compatibility path for the current iOS 17+ target and is deprecated in newer SDKs in favor of ScreenCaptureKit. It does not by itself prove unrestricted full-device mirroring across arbitrary apps.

## Next
Stage 5 — CarPlay Simulator and supported CarPlay scene/presentation configuration.
