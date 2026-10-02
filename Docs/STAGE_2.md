# Stage 2 — CarPlay Detection

Status: **Complete**

## Implemented
- Watches UIKit scene connect/disconnect notifications.
- Filters specifically for `UISceneSession.Role.carTemplateApplication`.
- Updates the SwiftUI interface when a CarPlay scene connects or disconnects.
- Refreshes connection state when the iPhone app becomes active.
- Adds a manual CarPlay status refresh button.

## Important runtime note
The detector reports a CarPlay connection when iOS creates a CarPlay application scene for BMW Mirror. Creating and presenting that scene still depends on the later CarPlay scene configuration and applicable Apple entitlement.

## Next
Stage 3 — Screen Capture.
