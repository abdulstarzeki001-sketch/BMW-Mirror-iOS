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
7. اختبار فعلي على BMW X6 2025

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
**Stage 1–5 مكتملة. Stage 6 مجهزة مجانًا، والمتبقي فيها موافقة Apple/التوقيع قبل اختبار CarPlay الحقيقي.**
