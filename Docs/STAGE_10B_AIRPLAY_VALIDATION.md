# Stage 10B — External AirPlay Validation Toolkit

Status: **Implementation complete; real receiver test pending.**

## Why this stage exists
A local AVPlayer successfully loading the generated HLS stream is not enough to prove AirPlay. The app now collects evidence from both the playback side and the HTTP-server side.

## Validation signals
The live validation screen now tracks:
- `AVPlayer.isExternalPlaybackActive`
- player keep-up state
- playback stall count
- external-playback transition time
- `AVRouteDetector.multipleRoutesDetected`
- current AVAudioSession route
- active Network.framework path/interfaces
- total HLS HTTP requests
- playlist requests
- media-segment requests
- likely external-client request count
- last HLS client endpoint
- last requested HLS resource
- total served bytes
- first-HLS-ready latency

## Strong success signal
The preferred runtime result is:
1. `isExternalPlaybackActive == true`
2. The HLS server sees requests attributable to an external client, or the receiver provides another verified playback signal.
3. Playback stays stable without repeated stalls.

## Report
The screen includes **مشاركة تقرير AirPlay** which exports the complete validation snapshot for later comparison between Apple TV/AirPlay receivers and the BMW test.

## Remaining physical work
A real AirPlay video receiver is still required. CI cannot prove receiver-side reachability or vehicle support.
