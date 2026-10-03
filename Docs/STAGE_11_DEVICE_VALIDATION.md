# Stage 11 — Pre-Entitlement Device Validation

Status: **Toolkit complete; physical iPhone run pending.**

## Purpose
This stage verifies everything that can be proven before paying for Apple Developer membership or requesting the CarPlay Video entitlement.

## Device Validation Center
The app now provides a dedicated screen that:
- distinguishes Simulator from a physical iPhone
- verifies `BMWMirrorBroadcast.appex` is embedded at runtime
- selects the expected full-display capture path for the running iOS version
- checks for a usable local IPv4 address
- probes `live.m3u8` when a live capture bridge is active
- shows the BMW Mirror CarPlay scene state without treating it as video proof
- generates a shareable validation report

## Passing sequence
The intended proof chain is:

```text
Physical iPhone
    ↓
Full-display capture
    ↓
Live HLS reachable
    ↓
External AirPlay playback
    ↓
CarPlay Video entitlement
    ↓
BMW X6 2025 validation
```

A Simulator pass is useful for compilation and packaging only. It cannot close the physical-device gates.
