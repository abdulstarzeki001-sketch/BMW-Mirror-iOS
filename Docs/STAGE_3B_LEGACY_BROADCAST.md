# Stage 3B — ReplayKit Broadcast Upload Extension

Status: **Implementation complete; physical iPhone validation pending.**

## Architecture

```text
iOS System Broadcast Picker
        ↓
BMWMirrorBroadcast.appex
        ↓
RPBroadcastSampleHandler
        ↓
CMSampleBuffer (video + app audio)
        ↓
LiveCaptureAirPlayBridge
        ↓
AVAssetWriter / Apple HLS
        ↓
HTTP port 8765 on iPhone
        ↓
BMW Mirror AVPlayer
        ↓
AirPlay
```

## Why this design
The upload extension is a separate process, so directly passing Swift objects to the host app is not possible. Instead of requiring an App Group for large media transfer, the extension creates the live HLS stream itself and exposes it through the iPhone network stack.

The host app derives the iPhone IPv4 address and uses the known fixed port.

## Implemented
- `BMWMirrorBroadcast` app-extension target.
- Product bundle ID: `com.abdulstar.bmwmirror.broadcast`.
- `RPSystemBroadcastPickerView`.
- `RPBroadcastSampleHandler`.
- `RPBroadcastProcessModeSampleBuffer`.
- Video + app-audio forwarding to the HLS bridge.
- Fixed HLS port: `8765`.
- Main-app legacy AirPlay player screen.
- One-second HLS health probe with latency and reachability state.
- Automatic AVPlayer loading when the Broadcast Extension server becomes reachable.
- App-extension embedding and target dependency.

## Important
ReplayKit broadcast APIs are deprecated on newer Apple platforms. This target exists only for iOS 17–26 compatibility.

A simulator build can verify compilation and project structure, but only a real iPhone can prove that system-wide broadcast starts, continues after leaving BMW Mirror, and serves live HLS correctly.
