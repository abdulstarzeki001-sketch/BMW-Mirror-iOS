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
  "Scripts/device-build.sh"
  "BroadcastExtension/Info.plist"
  "BroadcastExtension/SampleHandler.swift"
  "Core/AppConstants.swift"
  "Core/ProjectReadiness.swift"
  "Features/CarPlay/CarPlayManager.swift"
  "Features/CarPlay/CarPlaySceneDelegate.swift"
  "Features/CarPlay/CarPlayPreviewView.swift"
  "Features/ScreenCapture/CaptureMode.swift"
  "Features/ScreenCapture/ScreenCaptureManager.swift"
  "Features/ScreenCapture/FullDisplayCaptureController.swift"
  "Features/ScreenCapture/LegacyBroadcastPickerView.swift"
  "Features/Media/MediaPipeline.swift"
  "Features/Diagnostics/DiagnosticsReport.swift"
  "Features/Diagnostics/DeviceValidationManager.swift"
  "Features/Diagnostics/DeviceValidationCenterView.swift"
  "Features/AirPlay/AirPlayVideoManager.swift"
  "Features/AirPlay/AirPlayRoutePicker.swift"
  "Features/AirPlay/AirPlayProbeView.swift"
  "Features/AirPlay/AirPlayValidationManager.swift"
  "Features/AirPlay/AirPlayValidationReport.swift"
  "Features/AirPlay/LiveHLSStore.swift"
  "Features/AirPlay/LiveHLSSegmenter.swift"
  "Features/AirPlay/LiveHLSHTTPServer.swift"
  "Features/AirPlay/LiveCaptureAirPlayBridge.swift"
  "Features/AirPlay/LiveAirPlayBridgeView.swift"
  "Features/AirPlay/LegacyBroadcastAirPlayView.swift"
  "Features/AirPlay/LegacyBroadcastMonitor.swift"
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || fail "Missing required file: $file"
done
pass "Required project files are present"

grep -q "CPTemplateApplicationSceneSessionRoleApplication" BMWMirrorApp/Info.plist   || fail "CarPlay scene role is missing from Info.plist"
grep -q "CarPlaySceneDelegate" BMWMirrorApp/Info.plist   || fail "CarPlay scene delegate is missing from Info.plist"
grep -q "<string>screen-capture</string>" BMWMirrorApp/Info.plist   || fail "iOS 27 full-display capture background mode is missing"
grep -q "NSLocalNetworkUsageDescription" BMWMirrorApp/Info.plist   || fail "Local network usage description is missing"
grep -q "NSAllowsLocalNetworking" BMWMirrorApp/Info.plist   || fail "ATS local-network exception is missing"
pass "Host app plist configuration is present"

grep -q "com.apple.broadcast-services-upload" BroadcastExtension/Info.plist   || fail "Broadcast upload extension point is missing"
grep -q "RPBroadcastProcessModeSampleBuffer" BroadcastExtension/Info.plist   || fail "ReplayKit sample-buffer process mode is missing"
pass "ReplayKit Broadcast Upload Extension plist is configured"

grep -q "com.apple.developer.carplay-video" BMWMirrorApp/BMWMirror.entitlements.example   || fail "CarPlay video entitlement candidate is missing from example file"

if grep -q "CODE_SIGN_ENTITLEMENTS = BMWMirrorApp/BMWMirror.entitlements;" BMWMirror.xcodeproj/project.pbxproj; then
  fail "Real entitlement is active before Apple approval"
fi
pass "Real CarPlay entitlement is intentionally deferred"

grep -q "DEVELOPMENT_TEAM" Scripts/device-build.sh \
  || fail "Physical-device build script does not require a development team"
grep -q -- "-allowProvisioningUpdates" Scripts/device-build.sh \
  || fail "Physical-device build script is missing automatic provisioning support"
grep -q "Refusing device build" Scripts/device-build.sh \
  || fail "Physical-device build script lacks the entitlement safety guard"
pass "Physical-device signing preparation is guarded"

required_sources=(
  "CarPlaySceneDelegate.swift in Sources"
  "MediaPipeline.swift in Sources"
  "CaptureMode.swift in Sources"
  "FullDisplayCaptureController.swift in Sources"
  "ProjectReadiness.swift in Sources"
  "AirPlayVideoManager.swift in Sources"
  "AirPlayRoutePicker.swift in Sources"
  "AirPlayProbeView.swift in Sources"
  "AirPlayValidationManager.swift in Sources"
  "AirPlayValidationReport.swift in Sources"
  "LiveHLSStore.swift in Sources"
  "LiveHLSSegmenter.swift in Sources"
  "LiveHLSHTTPServer.swift in Sources"
  "LiveCaptureAirPlayBridge.swift in Sources"
  "LiveAirPlayBridgeView.swift in Sources"
  "LegacyBroadcastPickerView.swift in Sources"
  "LegacyBroadcastAirPlayView.swift in Sources"
  "LegacyBroadcastMonitor.swift in Sources"
  "DeviceValidationManager.swift in Sources"
  "DeviceValidationCenterView.swift in Sources"
  "SampleHandler.swift in Sources"
)

for source in "${required_sources[@]}"; do
  grep -q "$source" BMWMirror.xcodeproj/project.pbxproj     || fail "Missing Xcode source membership: $source"
done

grep -q "BMWMirrorBroadcast.appex" BMWMirror.xcodeproj/project.pbxproj   || fail "Broadcast extension product is missing from Xcode project"
grep -q "Embed App Extensions" BMWMirror.xcodeproj/project.pbxproj   || fail "Broadcast extension embed phase is missing"
grep -q "com.abdulstar.bmwmirror.broadcast" BMWMirror.xcodeproj/project.pbxproj   || fail "Broadcast extension bundle ID is missing"
pass "Host app + broadcast extension target membership is configured"

grep -q "processReplayKitVideoSampleBuffer" Features/ScreenCapture/ScreenCaptureManager.swift   || fail "Legacy ReplayKit path is not wired to the media pipeline"
grep -q "FullDisplayCaptureController" Features/ScreenCapture/ScreenCaptureManager.swift   || fail "Full-display ScreenCaptureKit path is not wired"
grep -q "RPSystemBroadcastPickerView" Features/ScreenCapture/LegacyBroadcastPickerView.swift   || fail "System broadcast picker is missing"
grep -q "LiveCaptureAirPlayBridge" BroadcastExtension/SampleHandler.swift   || fail "Broadcast extension is not wired to the HLS bridge"
grep -q "mpeg4AppleHLS" Features/AirPlay/LiveHLSSegmenter.swift   || fail "Live HLS segmenter is not using the Apple HLS profile"
grep -q "NWListener" Features/AirPlay/LiveHLSHTTPServer.swift   || fail "Live HLS HTTP server is missing"
grep -q "includePeerToPeer = true" Features/AirPlay/LiveHLSHTTPServer.swift   || fail "Peer-to-peer local HLS networking is not enabled"
grep -q "AVRouteDetector" Features/AirPlay/AirPlayValidationManager.swift   || fail "AirPlay route validation monitor is missing"
grep -q "AVPlayerItemPlaybackStalled" Features/AirPlay/AirPlayVideoManager.swift   || fail "Playback stall monitoring is missing"
grep -q "URLSession.shared.data" Features/AirPlay/LegacyBroadcastMonitor.swift   || fail "Legacy broadcast health monitor is missing"
grep -q "broadcastExtensionIsEmbedded" Features/Diagnostics/DeviceValidationManager.swift   || fail "Device validation does not verify the embedded broadcast extension"
grep -q "probeHLS" Features/Diagnostics/DeviceValidationManager.swift   || fail "Device validation does not probe Live HLS"
grep -q "DeviceValidationCenterView" Features/Home/HomeView.swift   || fail "Device Validation Center is not linked from Home"
pass "Capture, HLS, AirPlay and device-validation wiring is present"

python3 - <<'PY'
import plistlib
from pathlib import Path

with Path("BMWMirrorApp/Info.plist").open("rb") as f:
    app = plistlib.load(f)

manifest = app.get("UIApplicationSceneManifest", {})
configs = manifest.get("UISceneConfigurations", {})
role = configs.get("CPTemplateApplicationSceneSessionRoleApplication", [])

if not role:
    raise SystemExit("❌ Parsed plist has no CarPlay scene configuration")

entry = role[0]
if entry.get("UISceneClassName") != "CPTemplateApplicationScene":
    raise SystemExit("❌ CarPlay scene class is incorrect")

if "screen-capture" not in app.get("UIBackgroundModes", []):
    raise SystemExit("❌ screen-capture background mode is missing")

with Path("BroadcastExtension/Info.plist").open("rb") as f:
    ext = plistlib.load(f)

nsext = ext.get("NSExtension", {})
if nsext.get("NSExtensionPointIdentifier") != "com.apple.broadcast-services-upload":
    raise SystemExit("❌ Broadcast extension point is incorrect")

attrs = nsext.get("NSExtensionAttributes", {})
if attrs.get("RPBroadcastProcessMode") != "RPBroadcastProcessModeSampleBuffer":
    raise SystemExit("❌ Broadcast extension process mode is incorrect")

with Path("BMWMirrorApp/BMWMirror.entitlements.example").open("rb") as f:
    entitlements = plistlib.load(f)

if entitlements.get("com.apple.developer.carplay-video") is not True:
    raise SystemExit("❌ CarPlay video entitlement example is malformed")

print("✅ Plists and deferred entitlement example are structurally valid")
PY

echo "✅ BMW Mirror preflight completed successfully"
