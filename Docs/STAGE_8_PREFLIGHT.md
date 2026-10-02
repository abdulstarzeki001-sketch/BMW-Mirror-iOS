# Stage 8 — Preflight & Readiness

Status: **Complete**

## Added
- A Project Readiness screen in the iPhone app.
- A readiness model that separates completed work from external Apple/vehicle dependencies.
- `Scripts/preflight.sh` for fast repository sanity checks.
- GitHub Actions workflow `Project Preflight`.

## Preflight checks
- Required project files exist.
- CarPlay scene role exists in Info.plist.
- CarPlay scene delegate is configured.
- The deferred CarPlay video entitlement example exists.
- The real CarPlay entitlement is not attached prematurely.
- Key Swift files are present in the Xcode Sources phase.
- Info.plist parses correctly and contains the expected CarPlay scene class.

## Purpose
This stage reduces the chance of paying for the Apple Developer Program and then discovering a simple project-structure mistake.

## Remaining blockers
Only external/runtime items remain:
1. Apple Developer Program enrollment.
2. Apple approval for the applicable CarPlay entitlement.
3. Provisioning/signing with the approved entitlement.
4. Real BMW X6 2025 testing.
