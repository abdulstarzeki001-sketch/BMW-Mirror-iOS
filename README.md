# BMW Mirror iOS

تطبيق تجريبي لـ iPhone لاختبار التقاط الشاشة وتجهيز مسار عرض متوافق مع CarPlay ضمن APIs وصلاحيات Apple الرسمية.

## الحالة الحالية

- ✅ مشروع SwiftUI/Xcode — **Build ناجح في CI**
- ✅ اكتشاف مشهد CarPlay الخاص بالتطبيق
- ✅ ReplayKit لالتقاط محتوى BMW Mirror نفسه
- 🟡 iOS 17–26: الالتقاط الكامل يحتاج **ReplayKit Broadcast Upload Extension**
- ✅ iOS 27+: ScreenCaptureKit full-display path
- ✅ Media Pipeline + FPS/latency/diagnostics
- ✅ CarPlay template scene
- ✅ AirPlay playback probe
- ✅ **Live Capture → fragmented MP4/HLS bridge**
- ✅ Local HLS HTTP server + AVPlayer live playback path
- 🟡 **External AirPlay validation للـ Live HLS لم يتم بعد**
- 🟡 CarPlay Video entitlement غير مفعّل
- 🟡 اختبار BMW X6 2025 لم يتم بعد

## المسار الحالي لـ iOS 27+

```text
iPhone full display
    ↓
ScreenCaptureKit
    ↓
Media Pipeline
    ↓
AVAssetWriter
    ↓
fragmented MP4 / Apple HLS
    ↓
Rolling HLS playlist
    ↓
Local HTTP server
    ↓
AVPlayer
    ↓
AirPlay route picker
    ↓
External AirPlay validation  ← المرحلة الحالية
    ↓
CarPlay Video entitlement
    ↓
BMW X6 test
```

Apple HLS segment generation في المشروع يستخدم `AVAssetWriter.outputFileTypeProfile = .mpeg4AppleHLS` ومقاطع قصيرة لتقليل التأخير.

## iOS 17–26 compatibility

```text
System Broadcast Picker
    ↓
ReplayKit Broadcast Upload Extension   ← لم يُنفذ بعد
    ↓
Frame transport to BMW Mirror
    ↓
Live HLS bridge
    ↓
AirPlay / CarPlay
```

## فتح المشروع

افتح `BMWMirror.xcodeproj`، اختر iPhone Simulator ثم Run.

## اختبار Live AirPlay Bridge

من الصفحة الرئيسية:

1. ابدأ Screen Capture.
2. افتح **Live Capture → AirPlay**.
3. انتظر حتى تصبح حالة **Live HLS = جاهز لـ AVPlayer**.
4. اضغط **تحميل البث الحي**.
5. شغّل الفيديو محليًا.
6. استخدم زر AirPlay لاختيار مستقبل فيديو.

نجاح الفيديو داخل AVPlayer لا يعني تلقائيًا نجاح المستقبل الخارجي؛ يجب اختبار `isExternalPlaybackActive` على جهاز فعلي.

## Bundle ID

`com.abdulstar.bmwmirror`

## قبل الدفع

شغّل `bash Scripts/preflight.sh`.

لا تربط `BMWMirror.entitlements` الحقيقي بالتوقيع قبل موافقة Apple، ولا تعتبر المشروع جاهزًا للسيارة قبل نجاح External AirPlay على البث الحي.
