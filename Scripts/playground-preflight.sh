#!/usr/bin/env bash
set -euo pipefail

ROOT="Playgrounds/BMWMirrorPad.swiftpm"

fail() {
  echo "❌ $1"
  exit 1
}

pass() {
  echo "✅ $1"
}

required_files=(
  "$ROOT/Package.swift"
  "$ROOT/AdditionalInfo.plist"
  "$ROOT/BMWMirrorPadApp.swift"
  "$ROOT/MainView.swift"
  "$ROOT/PlaygroundAirPlayPlayer.swift"
  "$ROOT/PlaygroundAirPlayRoutePicker.swift"
  "$ROOT/PlaygroundDiagnostics.swift"
  "$ROOT/LiveCaptureTestView.swift"
  "$ROOT/PlaygroundHLSValidator.swift"
  "$ROOT/PlaygroundCaptureManager.swift"
  "$ROOT/PlaygroundLiveHLSBridge.swift"
  "$ROOT/README.md"
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || fail "Missing iPad playground file: $file"
done

grep -q "import AppleProductTypes" "$ROOT/Package.swift"   || fail "Swift Playgrounds manifest is missing AppleProductTypes"

grep -q ".iOSApplication" "$ROOT/Package.swift"   || fail "Swift Playgrounds manifest has no iOSApplication product"

grep -q "supportedDeviceFamilies" "$ROOT/Package.swift"   || fail "Swift Playgrounds device families are missing"

grep -q ".pad" "$ROOT/Package.swift"   || fail "iPad is not enabled in Swift Playgrounds package"

grep -q "additionalInfoPlistContentFilePath" "$ROOT/Package.swift"   || fail "Additional Info.plist is not attached to the playground"

grep -q "NSLocalNetworkUsageDescription" "$ROOT/AdditionalInfo.plist"   || fail "iPad local-network privacy description is missing"

grep -q "allowsExternalPlayback = true" "$ROOT/PlaygroundAirPlayPlayer.swift"   || fail "External AirPlay playback is not enabled"

grep -q "prioritizesVideoDevices = true" "$ROOT/PlaygroundAirPlayRoutePicker.swift"   || fail "AirPlay picker does not prioritize video devices"

grep -q "AVRouteDetector" "$ROOT/PlaygroundDiagnostics.swift"   || fail "AirPlay route diagnostics are missing"

grep -q "URLSession.shared.data" "$ROOT/PlaygroundDiagnostics.swift"   || fail "HLS reachability probe is missing"

grep -q "RPScreenRecorder.shared" "$ROOT/PlaygroundCaptureManager.swift"   || fail "ReplayKit live capture is missing from the iPad harness"

grep -q "mpeg4AppleHLS" "$ROOT/PlaygroundLiveHLSBridge.swift"   || fail "Live HLS encoding is missing from the iPad harness"

grep -q "NWListener" "$ROOT/PlaygroundLiveHLSBridge.swift"   || fail "Local HLS HTTP server is missing from the iPad harness"

grep -q "Live Capture → AirPlay" "$ROOT/MainView.swift"   || fail "Live capture test entry point is missing"

python3 - <<'PY'
import plistlib
from pathlib import Path

path = Path("Playgrounds/BMWMirrorPad.swiftpm/AdditionalInfo.plist")
with path.open("rb") as f:
    data = plistlib.load(f)

if "NSLocalNetworkUsageDescription" not in data:
    raise SystemExit("❌ Invalid playground AdditionalInfo.plist")

ats = data.get("NSAppTransportSecurity", {})
if ats.get("NSAllowsLocalNetworking") is not True:
    raise SystemExit("❌ NSAllowsLocalNetworking must be true")

print("✅ Swift Playgrounds AdditionalInfo.plist is valid")
PY

pass "BMW Mirror Pad playground structure is ready"


grep -q "AVURLAsset" "$ROOT/PlaygroundHLSValidator.swift"   || fail "AVFoundation live HLS self-validation is missing"
grep -q "CODECS=" "$ROOT/PlaygroundLiveHLSBridge.swift"   || fail "Master playlist CODECS attribute is missing"
grep -q "RESOLUTION=" "$ROOT/PlaygroundLiveHLSBridge.swift"   || fail "Master playlist RESOLUTION attribute is missing"
grep -q "Accept-Ranges: bytes" "$ROOT/PlaygroundLiveHLSBridge.swift"   || fail "HTTP byte-range support is missing"
