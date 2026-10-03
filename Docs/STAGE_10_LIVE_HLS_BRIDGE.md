# Stage 10 — Live Capture → HLS → AVPlayer Bridge

Status: **Implementation complete; external AirPlay validation pending.**

## Implemented

### Capture input
Accepted video frames from ReplayKit/ScreenCaptureKit are forwarded into the live bridge after the 30 FPS media-pipeline throttle. Application/system audio buffers are forwarded separately.

### Streaming encoder
`LiveHLSSegmenter` uses `AVAssetWriter` and:

```swift
outputFileTypeProfile = .mpeg4AppleHLS
preferredOutputSegmentInterval = 1 second
```

The writer emits CMAF-compatible fragmented MP4 initialization and media segments through `AVAssetWriterDelegate`.

### Rolling live playlist
`LiveHLSStore` keeps:
- initialization segment
- last 8 media segments
- segment durations
- media sequence
- generated live `.m3u8` playlist

### Local HTTP delivery
`LiveHLSHTTPServer` uses Network.framework `NWListener`.
It serves:
- `/live.m3u8`
- `/init.mp4`
- `/segment-xxxxx.m4s`

Peer-to-peer networking is enabled and the app declares Local Network usage plus ATS local-network access.

### Playback / AirPlay
`LiveAirPlayBridgeView` loads the generated HLS URL into `AVPlayer`.
The existing `AVRoutePickerView` remains the route selector and `AVPlayer.isExternalPlaybackActive` remains the validation signal.

## Verified
- Repository preflight passed.
- iOS Simulator build passed after adding the bridge.

## Not yet proven
A real AirPlay receiver may need to fetch the HLS URL from the iPhone. The next physical validation must confirm that the selected AirPlay receiver can reach the local HTTP endpoint across the active Wi-Fi/peer-to-peer interface.

If that network model fails, the transport layer must change; the project must not claim finished mirroring until external playback is proven.
