# BMW Mirror iOS

تطبيق iPhone تجريبي لبناء مسار رسمي قدر الإمكان من **التقاط شاشة iPhone → فيديو حي → AirPlay → CarPlay Video / BMW** ضمن APIs وصلاحيات Apple.

## الحالة الحالية

- ✅ Xcode/SwiftUI project
- ✅ CI Project Preflight
- ✅ iOS Simulator Build
- ✅ CarPlay app scene
- ✅ Media Pipeline
- ✅ AirPlay playback probe
- ✅ Live Capture → fragmented MP4 / Apple HLS
- ✅ Local HLS server + AVPlayer
- ✅ External AirPlay validation dashboard
- ✅ ReplayKit Broadcast Upload Extension لـ iOS 17–26
- ✅ ScreenCaptureKit full-display path لـ iOS 27+
- ✅ Device Validation Center قبل entitlement
- ✅ guarded physical-device signing script
- 🟡 External AirPlay receiver test
- 🟡 Real iPhone validation for the legacy broadcast extension
- 🟡 Apple CarPlay Video entitlement
- 🟡 BMW X6 2025 physical test

## iOS 27+ architecture

```text
iPhone Full Display
        ↓
ScreenCaptureKit
        ↓
Media Pipeline
        ↓
AVAssetWriter
        ↓
fragmented MP4 / Apple HLS
        ↓
Local HLS Server
        ↓
AVPlayer
        ↓
AirPlay
        ↓
CarPlay Video entitlement
        ↓
Supported BMW display
```

## iOS 17–26 compatibility architecture

```text
RPSystemBroadcastPickerView
        ↓
BMWMirrorBroadcast.appex
        ↓
RPBroadcastSampleHandler
        ↓
video + app-audio CMSampleBuffer
        ↓
AVAssetWriter / Apple HLS
        ↓
HTTP port 8765
        ↓
BMW Mirror AVPlayer
        ↓
AirPlay
```

هذا المسار لا يستخدم App Groups لنقل الفيديو. الـ Broadcast Upload Extension نفسه يبني HLS ويقدمه على منفذ ثابت.

## External AirPlay validation

صفحة **Live Capture → AirPlay** تعرض:

- `AVPlayer.isExternalPlaybackActive`
- playback stalls / keep-up
- HLS playlist/media request counts
- likely external-client requests
- last HTTP client endpoint
- first-HLS-ready latency
- AVRouteDetector
- current audio route
- Network.framework path/interfaces
- تقرير قابل للمشاركة

الاختبار لا يُعتبر ناجحًا لمجرد أن الفيديو يعمل محليًا. نحتاج دليلًا فعليًا على تشغيل خارجي، مثل:

```text
External Playback = true
        +
external HLS client requests / verified receiver playback
```

## Bundle IDs

Host app:

`com.abdulstar.bmwmirror`

ReplayKit Broadcast Upload Extension:

`com.abdulstar.bmwmirror.broadcast`

## فتح المشروع

افتح:

`BMWMirror.xcodeproj`

ثم اختر iPhone Simulator أو جهاز iPhone فعلي.

## الفحص قبل أي دفع

```bash
bash Scripts/preflight.sh
```

ولتحضير build موجّه لـ iPhone فعلي على Mac/Xcode:

```bash
DEVELOPMENT_TEAM=YOUR_TEAM_ID bash Scripts/device-build.sh
```

السكريبت يرفض التشغيل إذا تم ربط ملف CarPlay entitlement الحقيقي قبل الموافقة، ولا يخزن Team ID أو شهادات أو أسرار داخل GitHub.

داخل التطبيق استخدم **Device Validation Center** بعد التثبيت لتأكيد الجهاز، الـBroadcast Extension، مسار الالتقاط، الشبكة وLive HLS.

ولا تربط `BMWMirror.entitlements` الحقيقي قبل أن توافق Apple على entitlement المناسب.

## حدود الحالة الحالية

المشروع صار يملك المسارات البرمجية الأساسية، لكنه **ليس مثبتًا بعد كتطبيق mirroring ناجح على BMW**. ما زال مطلوبًا اختبار AirPlay/ReplayKit على جهاز حقيقي، ثم CarPlay Video entitlement، ثم اختبار BMW X6 2025 مع السيارة متوقفة وحسب القيود التي يفرضها النظام والسيارة.


## iPad / Swift Playgrounds

للتطوير والاختبار بدون Mac يوجد App Playground مستقل:

`Playgrounds/BMWMirrorPad.swiftpm`

يعمل على iPad داخل Swift Playgrounds ويختبر:

- Apple HLS playback
- Custom HLS URL
- AirPlay route picker
- `AVPlayer.isExternalPlaybackActive`
- HLS reachability + latency
- playback stalls / keep-up
- AVRouteDetector / AVAudioSession route
- Network.framework diagnostics
- تقرير اختبار قابل للمشاركة

هذا الـHarness لا يستبدل مشروع Xcode الكامل، ولا يحتوي على Broadcast Upload Extension أو CarPlay entitlement. هدفه أن يسمح باختبار HLS/AirPlay والشبكة مباشرة من iPad.
