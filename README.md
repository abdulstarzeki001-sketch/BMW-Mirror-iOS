# BMW Mirror iOS

تطبيق تجريبي لـ iPhone لاختبار التقاط الشاشة وتجهيز مسار عرض متوافق مع CarPlay ضمن APIs وصلاحيات Apple الرسمية.

## الحالة الحالية

- ✅ مشروع SwiftUI/Xcode — **Build ناجح في CI**
- ✅ اكتشاف مشهد CarPlay الخاص بالتطبيق
- ✅ ReplayKit لالتقاط محتوى BMW Mirror نفسه
- 🟡 iOS 17–26: الالتقاط الكامل يحتاج **ReplayKit Broadcast Upload Extension** ولم يُنفذ بعد
- ✅ iOS 27+: ScreenCaptureKit full-display path موجود
- ✅ Media Pipeline + FPS/latency/diagnostics
- ✅ CarPlay template scene
- 🟡 **AirPlay Video output غير منفذ بعد**
- 🟡 CarPlay Video entitlement غير مفعّل
- 🟡 اختبار BMW X6 2025 لم يتم بعد

> مهم: `RPScreenRecorder.startCapture` ليس Screen Mirroring كامل لكل تطبيقات iPhone. للأنظمة الأقدم يمكن استخدام ReplayKit Broadcast Upload Extension الذي يستقبل video/audio sample buffers أثناء البث، لكنه أصبح مسارًا قديمًا واستبدلته Apple بـ ScreenCaptureKit في الأنظمة الأحدث.

## المسار المستهدف

### iOS 27+

```text
iPhone full display
    ↓
ScreenCaptureKit
    ↓
Media Pipeline
    ↓
AirPlay Video output   ← blocker الحالي
    ↓
CarPlay Video entitlement
    ↓
Supported vehicle / BMW test
```

### iOS 17–26 compatibility

```text
System Broadcast Picker
    ↓
ReplayKit Broadcast Upload Extension
    ↓
Frame transport to BMW Mirror
    ↓
Media / AirPlay Video output
    ↓
CarPlay / BMW test
```

## فتح المشروع

افتح `BMWMirror.xcodeproj`، اختر iPhone Simulator ثم Run.

## Bundle ID

`com.abdulstar.bmwmirror`

## البنية

- `BMWMirror.xcodeproj/`
- `BMWMirrorApp/`
- `Core/`
- `Features/Home/`
- `Features/ScreenCapture/`
- `Features/Media/`
- `Features/CarPlay/`
- `Features/Diagnostics/`
- `UI/`
- `Scripts/`
- `Docs/`

## قبل الدفع

شغّل `bash Scripts/preflight.sh`.

لا تربط `BMWMirror.entitlements` الحقيقي بالتوقيع قبل موافقة Apple، ولا تعتبر المشروع جاهزًا للسيارة قبل نجاح AirPlay Video output.
