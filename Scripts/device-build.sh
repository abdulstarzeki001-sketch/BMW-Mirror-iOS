#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${DEVELOPMENT_TEAM:-}" ]]; then
  cat <<'EOF'
DEVELOPMENT_TEAM is required.

Example:
  DEVELOPMENT_TEAM=ABCDE12345 bash Scripts/device-build.sh

This script intentionally does not enable the CarPlay Video entitlement.
EOF
  exit 2
fi

CONFIGURATION="${CONFIGURATION:-Debug}"
DESTINATION="${DESTINATION:-generic/platform=iOS}"

if grep -q "CODE_SIGN_ENTITLEMENTS = BMWMirrorApp/BMWMirror.entitlements;" BMWMirror.xcodeproj/project.pbxproj; then
  echo "❌ Refusing device build: the real CarPlay entitlement file is attached before approval."
  exit 1
fi

echo "BMW Mirror device build"
echo "======================="
echo "Configuration: ${CONFIGURATION}"
echo "Destination:   ${DESTINATION}"
echo "Team:          ${DEVELOPMENT_TEAM}"
echo
echo "Host bundle:      com.abdulstar.bmwmirror"
echo "Broadcast bundle: com.abdulstar.bmwmirror.broadcast"
echo

bash Scripts/preflight.sh

xcodebuild \
  -project BMWMirror.xcodeproj \
  -scheme BMWMirror \
  -configuration "${CONFIGURATION}" \
  -destination "${DESTINATION}" \
  DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  build

echo "✅ Device-oriented signed build completed."
echo "Next: install/run through Xcode on the physical iPhone and open Device Validation Center."
