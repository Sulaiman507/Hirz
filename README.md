# حِرز — Hirz 🕌

تطبيق مواقيت صلاة يعمل **بدون إنترنت ١٠٠٪** (Offline-first) مبني بـ Flutter.

> A fully offline prayer times app built with Flutter — no APIs, no internet required.

## ✨ المميزات | Features

- 🕋 **حساب فلكي محلي** عبر مكتبة `adhan` — بدون أي خادم أو API
- 🌍 **+١٢٠ مدينة** مدمجة (عواصم ومدن كبرى حول العالم) + إمكانية إضافة مدينة بإحداثيات يدوية
- 🕌 **٩ طرق حساب**: أم القرى (افتراضي)، رابطة العالم الإسلامي، الهيئة المصرية، كراتشي، أمريكا الشمالية (ISNA)، تركيا، قطر، الكويت، دبي
- 📿 **مذهب العصر**: شافعي (افتراضي) أو حنفي
- ⏳ **وقت الإقامة** لكل صلاة مع فواصل قابلة للتعديل من الإعدادات
- ⏱️ **عدّاد تنازلي متحرك** للصلاة القادمة
- 📅 **التاريخ الهجري** (الخوارزمية الجدولية) والميلادي معاً
- 🌐 **عربي / إنجليزي** مع تبديل فوري ودعم RTL كامل
- 🌙 **وضع فاتح وداكن** بألوان فاخرة (كحلي وذهبي وأخضر زيتي)
- 🎨 انتقالات سلسة و micro-interactions ناعمة

## 🏗️ البنية المعمارية | Architecture

Clean Architecture من ثلاث طبقات مع إدارة حالة عبر Riverpod:

```
lib/
├── core/          # الثيم، الترجمة، الأدوات المشتركة (هجرى، تنسيق الوقت)
├── domain/        # الكيانات والواجهات و UseCases (Dart نقي — لا Flutter)
│   ├── entities/  # PrayerTime, City, AppSettings
│   ├── repositories/
│   └── usecases/
├── data/          # التنفيذ: adhan + قاعدة المدن JSON + SharedPreferences
│   ├── datasources/
│   ├── models/
│   └── repositories/
└── presentation/  # الشاشات والويدجتات و Providers (Riverpod)
    ├── providers/
    ├── screens/   # الرئيسية، اختيار المدينة، الإعدادات
    └── widgets/
```

**قواعد الطبقات:**
- `domain` لا تستورد Flutter أبداً (قابلة للاختبار النقي)
- `data` تنفّذ واجهات `domain`
- `presentation` تعتمد على الكل عبر Riverpod providers

## 📦 الاعتماديات | Dependencies

| الحزمة | الإصدار | الغرض |
|--------|---------|-------|
| `flutter_riverpod` | ^2.6.1 | إدارة الحالة |
| `adhan` | ^2.0.0 | الحساب الفلكي للمواقيت |
| `shared_preferences` | ^2.3.5 | تخزين الإعدادات محلياً |
| `flutter_localizations` | SDK | ترجمة عناصر النظام |
| `intl` | any | تنسيق التواريخ والأوقات |
| `flutter_animate` | ^4.5.2 | الأنيميشن والانتقالات |

## 🚀 التشغيل | Getting Started

```bash
flutter pub get
flutter run
```

يتطلب Flutter 3.22+ و Dart 3.4+.

## 🔄 CI/CD — بناء APK تلقائياً

كل push إلى `main` يشغّل GitHub Actions workflow (`.github/workflows/build.yml`):

1. إنشاء scaffold عبر `flutter create` ثم نسخ `lib/` و `assets/` و `pubspec.yaml` فوقه
2. `flutter analyze` + `flutter test`
3. `flutter build apk --release`
4. رفع الـ APK كـ artifact باسم `hirz-release-apk`

> **لماذا scaffold؟** المستودع يحتوي كود Dart فقط بدون مجلد `android/` — يولّده CI عند البناء، فيبقى المستودع خفيفاً وقابلاً للقراءة.

## 🧪 الاختبارات | Tests

- `test/prayer_times_test.dart`: ترتيب الأوقات الفلكية لمدن متعددة + منطق الإقامة + خطوط العرض العالية
- `test/hijri_date_test.dart`: التحقق من التحويل الهجري ضد تواريخ معلومة

## 📝 الترخيص

مشروع شخصي — جميع الحقوق محفوظة © 2026 Sulaiman507

</content>