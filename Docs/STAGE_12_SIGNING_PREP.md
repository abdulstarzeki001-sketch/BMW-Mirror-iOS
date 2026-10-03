# Stage 12A — Device Signing Preparation

Status: **Prepared; requires a Mac/Xcode signing session and an Apple account.**

## Goal

Prepare a physical-iPhone build **without activating the deferred CarPlay Video entitlement**.

## Script

```bash
DEVELOPMENT_TEAM=YOUR_TEAM_ID bash Scripts/device-build.sh
```

Optional:

```bash
CONFIGURATION=Debug \
DESTINATION='generic/platform=iOS' \
DEVELOPMENT_TEAM=YOUR_TEAM_ID \
bash Scripts/device-build.sh
```

The script:

- runs the full repository preflight first
- refuses to continue if the real CarPlay entitlement file is prematurely attached
- uses automatic signing
- passes one development team to the host app and embedded Broadcast Upload Extension
- builds the `BMWMirror` scheme for a physical-iOS destination
- does not store certificates, passwords, API keys, or team IDs in GitHub

## Bundle IDs

Host:

`com.abdulstar.bmwmirror`

Broadcast extension:

`com.abdulstar.bmwmirror.broadcast`

If either identifier is unavailable in the signing account, change both to unique identifiers while keeping the extension ID aligned with `AppConstants.legacyBroadcastExtensionBundleID`.

## Gate

A successful CI Simulator build is not a signing proof. This stage is complete as preparation only; the physical-device gate closes after Xcode signs and runs the host app plus extension on a real iPhone.
