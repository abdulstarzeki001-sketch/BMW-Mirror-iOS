# Stage 4 — Media Pipeline

Status: **Complete.**

## Input paths

```text
ReplayKit in-app capture ─┐
                         ├─> MediaPipeline
ScreenCaptureKit iOS 27+ ┘
```

## Video processing
- Target: 30 FPS.
- Throttles frames above the target rate.
- Normalizes ReplayKit orientation metadata.
- Keeps ScreenCaptureKit frames in their supplied orientation.
- Downscales the long edge to a maximum of 1280 px for the current preview/transport boundary.
- Converts frames to `CGImage` for preview.

## Metrics
The pipeline now keeps separate counters for:
- successfully processed frames
- throttled frames
- failed/conversion frames
- audio packets
- actual smoothed FPS
- frame processing latency

This fixes the earlier accounting issue where an accepted frame could be counted as processed even when image conversion failed.

## Current boundary
The pipeline produces a processed-frame boundary, but it is **not yet an AirPlay video stream**.

## Next
Encode/bridge the media into a genuine AirPlay-capable video playback/output path before requesting the CarPlay Video entitlement.
