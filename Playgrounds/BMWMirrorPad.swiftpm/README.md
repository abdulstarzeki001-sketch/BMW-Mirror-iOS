# BMW Mirror Pad.swiftpm

نسخة اختبار مستقلة تعمل داخل **Swift Playgrounds على iPad**.

## ماذا تختبر؟

- Apple HLS playback عبر AVPlayer
- Custom HLS URL
- HLS reachability + latency
- AirPlay route picker
- AVPlayer external playback state
- playback stalls / keep-up
- AVRouteDetector
- AVAudioSession route
- Network.framework path/interfaces
- تقرير اختبار قابل للمشاركة

## ماذا لا تختبر؟

هذه النسخة لا تحتوي على:
- ReplayKit Broadcast Upload Extension
- ScreenCaptureKit full-display capture
- CarPlay scene
- CarPlay Video entitlement

هذه الأشياء تبقى في مشروع Xcode الرئيسي.

## فتحها على iPad

1. ثبّت Swift Playgrounds من App Store.
2. من GitHub نزّل مجلد `BMWMirrorPad.swiftpm` كملف ZIP أو انسخه إلى Files.
3. إذا كان ZIP، فك الضغط.
4. تأكد أن اسم المجلد ينتهي بـ `.swiftpm`.
5. اضغط على المجلد من تطبيق Files واختر فتحه في Swift Playgrounds.
6. اضغط Run.

## أول اختبار

اضغط **استخدام Apple HLS Probe** ثم **تشغيل**.

بعدها اضغط زر **AirPlay** واختر أي مستقبل AirPlay Video متاح.

النتيجة المهمة:

```text
External Playback = نشط
```

## اختبار HLS من iPhone

إذا كان iPhone يشغّل BMWMirrorBroadcast على نفس الشبكة، اكتب في خانة الرابط:

```text
http://IP-OF-IPHONE:8765/live.m3u8
```

ثم:

1. فحص الرابط
2. تحميل الرابط
3. تشغيل
4. AirPlay
5. مشاركة تقرير الاختبار

## ملاحظة

Swift Playgrounds يستطيع إنشاء وتشغيل App projects على iPad، لكن هذا الـHarness هدفه الاختبار السريع فقط. المشروع الكامل مع Broadcast Extension وCarPlay يبقى في `BMWMirror.xcodeproj`.
