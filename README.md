# BMW Mirror iOS

تطبيق تجريبي لـ iPhone لاختبار التقاط الشاشة وتجهيز مسار عرض متوافق مع CarPlay ضمن APIs وصلاحيات Apple الرسمية.

## الحالة الحالية

- ✅ مشروع SwiftUI/Xcode
- ✅ اكتشاف مشهد CarPlay الخاص بالتطبيق
- ✅ ReplayKit كمسار توافق لالتقاط **محتوى التطبيق نفسه**
- ✅ ScreenCaptureKit full-display path لـ **iOS 27+**
- ✅ Media Pipeline + FPS/latency/diagnostics
- ✅ CarPlay template scene
- 🟡 **AirPlay Video output غير منفذ بعد**
- 🟡 CarPlay Video entitlement غير مفعّل
- 🟡 اختبار BMW X6 2025 لم يتم بعد

> مهم: ReplayKit الموجود في المشروع ليس Screen Mirroring كامل لكل تطبيقات iPhone. الالتقاط الكامل الرسمي موجود عبر ScreenCaptureKit على iOS 27+، لكن إرسال هذا الالتقاط إلى CarPlay ما زال يحتاج طبقة AirPlay Video فعلية ثم entitlement المناسب ودعم السيارة.

## الهدف التقني

المسار المستهدف:

```text
iPhone full display
    ↓
ScreenCaptureKit (iOS 27+)
    ↓
Media Pipeline
    ↓
AirPlay Video output   ← المرحلة البرمجية التالية
    ↓
CarPlay Video App entitlement
    ↓
Supported vehicle / BMW test
```

## فتح المشروع

افتح:

`BMWMirror.xcodeproj`

ثم اختر iPhone Simulator واضغط Run.

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

شغّل:

`bash Scripts/preflight.sh`

ولا تربط `BMWMirror.entitlements` الحقيقي بالتوقيع قبل أن توافق Apple على entitlement المناسب.
