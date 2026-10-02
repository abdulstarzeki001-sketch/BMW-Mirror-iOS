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
  "Features/CarPlay/CarPlaySceneDelegate.swift"
  "Features/CarPlay/CarPlayPreviewView.swift"
  "Features/ScreenCapture/ScreenCaptureManager.swift"
  "Features/Media/MediaPipeline.swift"
  "Features/Diagnostics/DiagnosticsReport.swift"
  "BMWMirrorApp/BMWMirror.entitlements.example"
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || fail "Missing required file: $file"
done
pass "Required project files are present"

grep -q "CPTemplateApplicationSceneSessionRoleApplication" BMWMirrorApp/Info.plist   || fail "CarPlay scene role is missing from Info.plist"
pass "CarPlay scene role is configured"

grep -q "CarPlaySceneDelegate" BMWMirrorApp/Info.plist   || fail "CarPlay scene delegate is missing from Info.plist"
pass "CarPlay scene delegate is configured"

grep -q "com.apple.developer.carplay-video" BMWMirrorApp/BMWMirror.entitlements.example   || fail "CarPlay video entitlement candidate is missing from example file"
pass "Deferred entitlement example is present"

if grep -q "CODE_SIGN_ENTITLEMENTS = BMWMirrorApp/BMWMirror.entitlements;" BMWMirror.xcodeproj/project.pbxproj; then
  fail "Real entitlement is active before Apple approval"
fi
pass "Real CarPlay entitlement is not prematurely attached to signing"

grep -q "CarPlaySceneDelegate.swift in Sources" BMWMirror.xcodeproj/project.pbxproj   || fail "CarPlaySceneDelegate is not included in Xcode Sources"

grep -q "MediaPipeline.swift in Sources" BMWMirror.xcodeproj/project.pbxproj   || fail "MediaPipeline is not included in Xcode Sources"
pass "Core Swift files are included in the Xcode target"

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

print("✅ Info.plist parses and CarPlay scene configuration is structurally valid")
PY

echo "✅ BMW Mirror preflight completed successfully"
