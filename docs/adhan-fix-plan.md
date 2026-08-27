# خطة إصلاح نظام الأذان المجدول — Hirz App

## المشاكل المُحدّدة
1. **`nextMidnight` crash** — `DateTime(year, month, day + 1)` يمكن ينهار في نهاية الشهر
2. **إذن المنبه الدقيق** — جدولة بدون تحقق نهائي → فشل صامت
3. **إعادة التشغيل** — لا يوجد `BootReceiver` لإعادة جدولة الأذان بعد reboot
4. **تشخيص ضعيف** — المستخدم ما يعرف سبب الفشل

## المراحل

### المرحلة 1: إصلاح علة `nextMidnight`
- **الملف**: `lib/presentation/screens/home_screen.dart`
- **التعديل**: استخدام `DateTime.now().add(const Duration(days: 1))` بدل حساب يدوي
- **التحقق**: `dart format` + فحص منطقي

### المرحلة 2: فحص إذن المنبه الدقيق قبل الجدولة
- **الملف**: `lib/core/services/adhan_notification_service.dart`
- **التعديل**: 
  - إضافة `requireExactAlarm()` يُستدعى قبل `scheduleAdhan()`
  - يرمي `StateError` واضح إذا الإذن غير مفعّل
- **الملف**: `lib/main.dart`
- **التعديل**: استدعاء `requireExactAlarm()` في `_reschedule()` قبل الحساب

### المرحلة 3: إضافة `BootReceiver` لإعادة الجدولة
- **الملف**: `scripts/android_patches.py`
- **التعديل**: إنشاء `BootReceiver.java` في `android/app/src/main/java/dev/hirz/`
- **الملف**: `android_patches.py`
- **التعديل**: إضافة `RECEIVE_BOOT_COMPLETED` permission + `receiver` في `AndroidManifest.xml`

### المرحلة 4: تحسين لوحة التشخيص
- **الملف**: `lib/presentation/screens/settings_screen.dart`
- **التعديل**: إضافة حالة `exactAlarmGranted` بشكل أوضح مع أزرار إجراء

## الترتيب
1. المرحلة 1 (5 دقائق)
2. المرحلة 2 (10 دقائق)
3. push + CI watch
4. المرحلة 3 (15 دقيقة)
5. push + CI watch
6. المرحلة 4 (10 دقائق)
7. push + CI watch نهائي

## التحقق بعد كل مرحلة
- `dart format lib`
- commit + push
- مراقبة CI حتى النجاح
- اختبار يدوي على APK
