# Stage 9 — AirPlay Playback Probe

Status: **Implemented; device/AirPlay receiver test pending.**

## Implemented
- `AVPlayer` with `allowsExternalPlayback = true`.
- `usesExternalPlaybackWhileExternalScreenIsActive = true`.
- `AVAudioSession` playback category with AirPlay allowed.
- `AVRoutePickerView` with video devices prioritized.
- External playback state monitoring through `AVPlayer.isExternalPlaybackActive`.
- In-app `AirPlayProbeView`.
- Apple-hosted HLS sample used only as a playback probe.

## What this proves
This stage gives BMW Mirror a normal AirPlay-capable video playback path that can be tested without pretending the live screen-capture frames already flow through it.

## What it does not prove
The HLS probe is not the live iPhone screen. The remaining engineering problem is to encode/bridge captured frames into a media source that `AVPlayer` can play externally through AirPlay.

## Next
Live Capture → AirPlay Bridge.
