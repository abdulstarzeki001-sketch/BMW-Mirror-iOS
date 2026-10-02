# BMW Mirror iOS

تطبيق iPhone تجريبي يهدف إلى اختبار مشاركة/عرض المحتوى على شاشة BMW عبر CarPlay ضمن القيود الرسمية لنظام iOS.

## الهدف
بناء المشروع على مراحل واضحة:
1. ✅ هيكل تطبيق SwiftUI ومشروع Xcode قابل للبناء
2. ⏳ حالة اتصال CarPlay
3. التقاط الشاشة داخل iPhone
4. معالجة الفيديو والصوت
5. ✅ CarPlay scene / Simulator preparation
6. ⏳ تجهيز Entitlements
7. 🟡 تجهيز واختبار BMW X6 2025
8. ✅ Preflight & Project Readiness

> عرض المحتوى على CarPlay يعتمد على الصلاحيات التي تمنحها Apple وعلى قدرات السيارة. المشروع لا يعتمد على تجاوز قيود السلامة أثناء القيادة.

## فتح المشروع
افتح:
`BMWMirror.xcodeproj`

ثم اختر iPhone Simulator واضغط Run.

## البنية
- `BMWMirror.xcodeproj/`
- `BMWMirrorApp/`
- `Core/`
- `Features/Home/`
- `Features/ScreenCapture/`
- `Features/CarPlay/`
- `UI/`
- `Docs/`

## المرحلة الحالية
**تم إنجاز البناء المجاني + فحوص Preflight. المتبقي خارجي فقط: اشتراك Apple Developer، موافقة entitlement، التوقيع، ثم الاختبار الفعلي على BMW.**
