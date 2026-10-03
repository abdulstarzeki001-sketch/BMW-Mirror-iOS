#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "❌ $1"
  exit 1
}

pass() {
  echo "✅ $1"
}

required_files=(
  "BMWMirror.xcodeproj/project.pbxproj"
  "BMWMirrorApp/Info.plist"
  "BMWMirrorApp/BMWMirrorApp.swift"
  "BMWMirrorApp/BMWMirror.entitlements.example"
  "Core/AppConstants.swift"
  "Core/ProjectReadiness.swift"
  "Features/CarPlay/CarPlayManager.swift"
  "Features/CarPlay/CarPlaySceneDelegate.swift"
  "Features/CarPlay/CarPlayPreviewView.swift"
  "Features/ScreenCapture/CaptureMode.swift"
  "Features/ScreenCapture/ScreenCaptureManager.swift"
  "Features/ScreenCapture/FullDisplayCaptureController.swift"
  "Features/Media/MediaPipeline.swift"
  "Features/Diagnostics/DiagnosticsReport.swift"
  "Features/AirPlay/AirPlayVideoManager.swift"
  "Features/AirPlay/AirPlayRoutePicker.swift"
  "Features/AirPlay/AirPlayProbeView.swift"
  "Features/AirPlay/LiveHLSStore.swift"
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || fail "Missing required file: $file"
done
pass "Required project files are present"

grep -q "CPTemplateApplicationSceneSessionRoleApplication" BMWMirrorApp/Info.plist   || fail "CarPlay scene role is missing from Info.plist"
pass "CarPlay scene role is configured"

grep -q "CarPlaySceneDelegate" BMWMirrorApp/Info.plist   || fail "CarPlay scene delegate is missing from Info.plist"
pass "CarPlay scene delegate is configured"

grep -q "<string>screen-capture</string>" BMWMirrorApp/Info.plist   || fail "iOS 27 full-display capture background mode is missing"
pass "ScreenCaptureKit background mode is declared"

grep -q "com.apple.developer.carplay-video" BMWMirrorApp/BMWMirror.entitlements.example   || fail "CarPlay video entitlement candidate is missing from example file"
pass "Deferred entitlement example is present"

if grep -q "CODE_SIGN_ENTITLEMENTS = BMWMirrorApp/BMWMirror.entitlements;" BMWMirror.xcodeproj/project.pbxproj; then
  fail "Real entitlement is active before Apple approval"
fi
pass "Real CarPlay entitlement is not prematurely attached to signing"

required_sources=(
  "CarPlaySceneDelegate.swift in Sources"
  "MediaPipeline.swift in Sources"
  "CaptureMode.swift in Sources"
  "FullDisplayCaptureController.swift in Sources"
  "ProjectReadiness.swift in Sources"
  "AirPlayVideoManager.swift in Sources"
  "AirPlayRoutePicker.swift in Sources"
  "AirPlayProbeView.swift in Sources"
  "LiveHLSStore.swift in Sources"
)

for source in "${required_sources[@]}"; do
  grep -q "$source" BMWMirror.xcodeproj/project.pbxproj     || fail "Missing Xcode source membership: $source"
done
pass "Core Swift files are included in the Xcode target"

grep -q "processReplayKitVideoSampleBuffer" Features/ScreenCapture/ScreenCaptureManager.swift   || fail "Legacy ReplayKit path is not wired to the media pipeline"

grep -q "FullDisplayCaptureController" Features/ScreenCapture/ScreenCaptureManager.swift   || fail "Full-display ScreenCaptureKit path is not wired"

grep -q "AirPlay Playback Probe" Core/ProjectReadiness.swift   || fail "AirPlay playback probe is not represented in readiness"

grep -q "Live Capture → AirPlay Bridge" Core/ProjectReadiness.swift   || fail "Live capture to AirPlay blocker is not represented in readiness"

grep -q "allowsExternalPlayback = true" Features/AirPlay/AirPlayVideoManager.swift   || fail "AVPlayer external playback is not enabled"

grep -q "prioritizesVideoDevices = true" Features/AirPlay/AirPlayRoutePicker.swift   || fail "AirPlay route picker is not prioritizing video devices"

grep -q "mpeg4AppleHLS" Features/AirPlay/LiveHLSSegmenter.swift   || fail "Live HLS segmenter is not using the Apple HLS profile"

grep -q "NWListener" Features/AirPlay/LiveHLSHTTPServer.swift   || fail "Live HLS HTTP server is missing"

grep -q "liveBridge.appendVideo" Features/ScreenCapture/ScreenCaptureManager.swift   || fail "Capture is not wired into the live HLS bridge"

pass "Capture, HLS bridge and AirPlay playback paths are wired"

python3 - <<'PY'
import plistlib
from pathlib import Path

with Path("BMWMirrorApp/Info.plist").open("rb") as f:
    data = plistlib.load(f)

manifest = data.get("UIApplicationSceneManifest", {})
configs = manifest.get("UISceneConfigurations", {})
role = configs.get("CPTemplateApplicationSceneSessionRoleApplication", [])

if not role:
    raise SystemExit("❌ Parsed plist has no CarPlay scene configuration")

entry = role[0]
if entry.get("UISceneClassName") != "CPTemplateApplicationScene":
    raise SystemExit("❌ CarPlay scene class is incorrect")

if "screen-capture" not in data.get("UIBackgroundModes", []):
    raise SystemExit("❌ screen-capture background mode is missing")

with Path("BMWMirrorApp/BMWMirror.entitlements.example").open("rb") as f:
    entitlements = plistlib.load(f)

if entitlements.get("com.apple.developer.carplay-video") is not True:
    raise SystemExit("❌ CarPlay video entitlement example is malformed")

print("✅ Plists parse and key configurations are structurally valid")
PY

echo "✅ BMW Mirror preflight completed successfully"
