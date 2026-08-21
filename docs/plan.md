# Hirz v2 — خطة التنفيذ (Implementation Plan)

تطبيق مواقيت صلاة Offline-first باسم "حِرز". Clean Architecture + Riverpod + adhan.
المستودع: Sulaiman507/Hirz (فارغ). البناء عبر GitHub Actions فقط (لا Flutter محلياً).

## Global Constraints (تُلزم كل المهام)
1. **Offline 100%**: ممنوع أي HTTP/API/إنترنت في كود التطبيق. كل البيانات من assets أو SharedPreferences.
2. **Clean Architecture**: domain لا تستورد Flutter أبداً (dart:core فقط). data تستورد domain. presentation تستورد الكل.
3. **Riverpod** لإدارة الحالة. لا setState إلا للـ Timer.
4. **عربي/إنجليزي** مع تبديل فوري، RTL تلقائي.
5. تعليقات ثنائية اللغة موجزة في الكود.
6. أحدث إصدارات stable مثبتة فعلياً: adhan 2.0.0+1, flutter_riverpod 2.6.1, shared_preferences 2.3.5, intl 0.19.0, flutter_animate 4.5.2.
7. لا خطوط مخصصة في v1 (خطوط النظام) — مرحلة التصميم لاحقاً.
8. لا إشعارات، لا قبلة، لا أذكار.

## هيكل الملفات الكامل
```
lib/
├── main.dart
├── core/
│   ├── theme/app_colors.dart
│   ├── theme/app_theme.dart
│   ├── utils/hijri_date.dart
│   ├── utils/time_formatter.dart
│   ├── l10n/app_localizations.dart
│   └── widgets/glass_card.dart
├── domain/
│   ├── entities/prayer_time.dart        (enum Prayer + entity)
│   ├── entities/city.dart
│   ├── entities/app_settings.dart
│   ├── repositories/prayer_times_repository.dart
│   ├── repositories/city_repository.dart
│   ├── repositories/settings_repository.dart
│   └── usecases/get_prayer_times.dart
│   └── usecases/search_cities.dart
│   └── usecases/save_settings.dart
├── data/
│   ├── datasources/prayer_times_local_datasource.dart  (adhan)
│   ├── datasources/city_local_datasource.dart          (cities.json)
│   ├── datasources/settings_local_datasource.dart      (SharedPreferences)
│   ├── models/city_model.dart
│   └── repositories/
│       ├── prayer_times_repository_impl.dart
│       ├── city_repository_impl.dart
│       └── settings_repository_impl.dart
├── presentation/
│   ├── providers/app_providers.dart
│   ├── providers/prayer_providers.dart
│   ├── providers/city_providers.dart
│   ├── providers/settings_providers.dart
│   ├── screens/home_screen.dart
│   ├── screens/city_selection_screen.dart
│   ├── screens/settings_screen.dart
│   └── widgets/
│       ├── prayer_card.dart
│       ├── countdown_timer.dart
│       ├── date_header.dart
│       └── manual_coordinates_form.dart
├── l10n/app_ar.json  (أصل الترجمات — العربية)
└── l10n/app_en.json
assets/data/cities.json
test/prayer_times_test.dart
test/hijri_date_test.dart
.github/workflows/build.yml
pubspec.yaml
analysis_options.yaml
README.md
.gitignore
```

## العقود (Contracts) — مرجع ثابت لكل المهام

### enums و entities (domain)
```dart
// prayer_time.dart
enum Prayer { fajr, sunrise, dhuhr, asr, maghrib, isha }

class PrayerTime {
  final Prayer prayer;
  final DateTime time;       // وقت الأذان
  final DateTime iqamahTime; // وقت الإقامة
  const PrayerTime({required this.prayer, required this.time, required this.iqamahTime});
}

class DailyPrayerTimes {
  final DateTime date;
  final List<PrayerTime> times; // مرتبة: فجر..عشاء
  PrayerTime? nextPrayer(DateTime now); // أول صلاة وقتها بعد now
  PrayerTime? currentPrayer(DateTime now); // آخر صلاة دخل وقتها
  const DailyPrayerTimes({required this.date, required this.times});
}

// city.dart
class City {
  final String id;
  final String nameEn;
  final String nameAr;
  final String countryEn;
  final String countryAr;
  final double latitude;
  final double longitude;
  final double timezoneOffsetHours; // إزاحة UTC ثابتة (offline)
  final bool isCustom; // مدينة أدخلها المستخدم يدوياً
  const City({...});
}

// app_settings.dart
enum CalculationMethod { ummAlQura, muslimWorldLeague, egyptian, karachi, northAmerica, turkey, qatar, kuwait, dubai }
enum Madhab { shafi, hanafi }

class AppSettings {
  final String languageCode;           // 'ar' | 'en'
  final bool isDarkMode;
  final CalculationMethod method;
  final Madhab madhab;
  final bool use24HourFormat;
  final Map<String, int> iqamahOffsets; // مفاتيح: fajr,sunrise,dhuhr,asr,maghrib,isha بالدقائق
  static const Map<String,int> defaultIqamahOffsets = {'fajr':20,'sunrise':15,'dhuhr':15,'asr':15,'maghrib':10,'isha':20};
  const AppSettings({...});
  AppSettings copyWith({...});
}
```

### repository interfaces (domain) — كلها async
```dart
abstract class PrayerTimesRepository {
  Future<DailyPrayerTimes> getPrayerTimes({required City city, required DateTime date, required AppSettings settings});
}
abstract class CityRepository {
  Future<List<City>> getAllCities();
  Future<List<City>> searchCities(String query);
  Future<City?> getSavedCity();
  Future<void> saveCity(City city);        // يحفظ id إن كانت من القائمة، أو كامل المدينة إن custom
  Future<void> saveCustomCity(City city);
}
abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
}
```

### adhan API (مهم — الأسماء الصحيحة في adhan 2.x Dart)
```dart
import 'package:adhan/adhan.dart';
final coordinates = Coordinates(city.latitude, city.longitude);
final params = CalculationMethod.ummAlQura.getParameters();
// أسماء CalculationMethod في المكتبة: muslimWorldLeague, egyptian, karachi, ummAlQura, dubai, moonsightingCommittee, northAmerica, kuwait, qatar, singapore, turkey, tehran
params.madhab = Madhab.shafi; // أو Madhab.hanafi
params.highLatitudeRule = HighLatitudeRule.middleOfTheNight;
final pt = PrayerTimes(coordinates, DateComponents.from(date), params);
pt.fajr; pt.sunrise; pt.dhuhr; pt.asr; pt.maghrib; pt.isha; // كلها DateTime
```
مطابقة CalculationMethod الخاصة بنا → مكتبة adhan:
ummAlQura→ummAlQura, muslimWorldLeague→muslimWorldLeague, egyptian→egyptian, karachi→karachi, northAmerica→northAmerica, turkey→turkey, qatar→qatar, kuwait→kuwait, dubai→dubai.

### تنسيق المدن cities.json
```json
{"id":"sa_makkah","nameEn":"Makkah","nameAr":"مكة المكرمة","countryEn":"Saudi Arabia","countryAr":"السعودية","latitude":21.4225,"longitude":39.8262,"timezoneOffsetHours":3}
```
~120 مدينة: كل عواصم العالم العربي + المدن الكبرى عالمياً.

### SharedPreferences keys
`language_code`, `is_dark_mode`, `calculation_method`, `madhab`, `use_24_hour`, `iqamah_offsets` (JSON string), `saved_city_id`, `saved_custom_city` (JSON string).
**قاعدة صارمة**: كل قراءة/كتابة prefs عبر متغيرات مُعرفة بوضوح مع أنواع صحيحة — لا `Future` عائم ولا خلط `dynamic`/`Map` بدون cast صريح.

### التقويم الهجري (hijri_date.dart)
خوارزمية الكويت/الجدولية (tabular Islamic calendar, civil epoch) — دالة نقية:
`HijriDate hijriFromDate(DateTime gregorian)` ترجع `{year, month, day}` مع أسماء الأشهر بالعربية والإنجليزية.

## CI workflow (.github/workflows/build.yml)
```yaml
name: Build Hirz APK
on:
  push:
    branches: [ main ]
  workflow_dispatch:
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: '17' }
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - name: Scaffold project
        run: |
          flutter create -t app --org dev.hirz --project-name hirz scaffold
          rm -rf scaffold/lib scaffold/test
          cp -r lib scaffold/lib
          cp -r assets scaffold/assets
          cp pubspec.yaml analysis_options.yaml scaffold/
          mkdir -p scaffold/test && cp -r test/. scaffold/test/
      - name: Get dependencies
        working-directory: scaffold
        run: flutter pub get
      - name: Analyze
        working-directory: scaffold
        run: flutter analyze --no-fatal-infos
      - name: Test
        working-directory: scaffold
        run: flutter test
      - name: Build APK
        working-directory: scaffold
        run: flutter build apk --release
      - uses: actions/upload-artifact@v4
        with:
          name: hirz-release-apk
          path: scaffold/build/app/outputs/flutter-apk/app-release.apk
```
ملاحظة: لا تصريح INTERNET في AndroidManifest (offline). في scaffold الجديد لا يوجد INTERNET افتراضياً — تحقق إن وُجد فاحذفه.

## المهام (Tasks)

### Task 1 — الهيكل + pubspec + CI
الملفات: pubspec.yaml, analysis_options.yaml, .gitignore, .github/workflows/build.yml, lib/main.dart (مؤقت بسيط: MaterialApp فارغ بـ scaffold يجمع الـ theme و locale delegates استعداداً)، assets/data/cities.json **فارغ مبدئياً** `[]` ليُملأ في المهمة 3.
pubspec:
```yaml
name: hirz
description: حِرز — تطبيق مواقيت صلاة يعمل بدون إنترنت
version: 1.0.0+1
environment:
  sdk: ">=3.4.0 <4.0.0"
dependencies:
  flutter: { sdk: flutter }
  flutter_localizations: { sdk: flutter }
  intl: any  # flutter_localizations يثبّت إصدار intl الصارم — any يمنع تعارض الحل
  flutter_riverpod: ^2.6.1
  adhan: ^2.0.0
  shared_preferences: ^2.3.5
  flutter_animate: ^4.5.2
dev_dependencies:
  flutter_test: { sdk: flutter }
  flutter_lints: ^5.0.0
flutter:
  uses-material-design: true
  assets:
    - assets/data/
    - lib/l10n/
```

### Task 2 — طبقة Domain
كل ملفات domain/ المذكورة أعلاه + usecases:
- GetPrayerTimes(call: {city, date, settings}) → يستدعي PrayerTimesRepository
- SearchCities(query), GetAllCities, GetSavedCity, SaveCity
- GetSettings, SaveSettings
UseCases بنمط `Future<T> call(...)`.

### Task 3 — طبقة Data
- prayer_times_local_datasource.dart: غلاف adhan حسب العقد أعلاه (بما فيها HighLatitudeRule.middleOfTheNight دائماً).
- city_local_datasource.dart: تحميل `assets/data/cities.json` عبر rootBundle + بحث (nameEn/nameAr/countryEn/countryAr).
- settings_local_datasource.dart: SharedPreferences بقواعد الأنواع الصارمة.
- models/city_model.dart: fromJson/toJson.
- repositories impl الثلاثة.
- **قاعدة المدن**: املأ assets/data/cities.json بـ ~120 مدينة حقيقية (إحداثيات دقيقة معروفة): كل العواصم العربية، مدن السعودية الرئيسية، عواصم أوروبا/آسيا/أمريكا/أفريقيا، والمدن الكبرى (لندن، نيويورك، طوكيو، إسطنبول، كوالالمبور، جاكرتا...). timezoneOffsetHours صحيحة لكل مدينة.
- test/prayer_times_test.dart: اختبارات نقية لوحدة الحساب (بدون SharedPreferences): تحقق أن أوقات مكة ليوم معلوم منطقية (الفجر قبل الشروق قبل الظهر...) وأن الإقامة = الأذان + offset.

### Task 4 — l10n + الثيم + الأدوات
- core/l10n/app_localizations.dart: delegate مخصص يحمّل lib/l10n/app_ar.json و app_en.json عبر rootBundle (لا تعتمد على flutter gen-l10n).
- lib/l10n/app_ar.json و app_en.json: كل النصوص (أسماء الصلوات، الشاشات، الإعدادات، طرق الحساب، المذاهب، أسماء الأشهر الهجرية والميلادية والأيام...).
- core/theme/app_colors.dart: كحلي navy #0A1128/#0F1B33، ذهبي gold #C9A227/#D4AF37، أخضر زيتي olive #6B8E23/#556B2F، أسود دافئ #12100E، فاتح off-white #F7F4EE.
- core/theme/app_theme.dart: ThemeData light + dark (Material 3) مع ColorScheme من الألوان أعلاه.
- core/utils/hijri_date.dart + test/hijri_date_test.dart (تحقق من تواريخ معلومة).
- core/utils/time_formatter.dart: تنسيق 12/24 ساعة حسب الإعدادات.

### Task 5 — طبقة Presentation
- providers/: sharedPreferencesProvider (FutureProvider)، repositories providers، selectedCityProvider، prayerTimesProvider (يعيد الحساب عند تغيير المدينة/التاريخ/الإعدادات)، settingsProvider (StateNotifier أو AsyncNotifier)، localeProvider مشتق من الإعدادات، countdownProvider منطق (وقت الصلاة القادمة والمتبقي).
- screens الثلاثة:
  - home: تاريخ هجري/ميلادي، قائمة الصلوات الخمس + الشروق مع الإقامة، تمييز الصلاة القادمة، العدّاد التنازلي، زر تغيير المدينة، زر الإعدادات.
  - city_selection: بحث فوري + قائمة + حفظ، + نموذج إحداثيات يدوية (manual_coordinates_form مع تحقق من صحة lat -90..90, lng -180..180).
  - settings: اللغة (ع/إن)، الثيم، طريقة الحساب، المذهب، تنسيق الوقت، تعديل offsets الإقامة لكل صلاة.
- widgets: prayer_card, countdown_timer (Timer.periodic كل ثانية، يعرض HH:MM:SS متبقي واسم الصلاة القادمة), date_header, glass_card.
- main.dart النهائي: ProviderScope → Consumer يقرأ locale+theme من settingsProvider → MaterialApp مع AnimatedTheme و Localizations delegates (AppLocalizations + GlobalMaterial/Widgets/Cupertino) و supportedLocales ثابتة `[Locale('ar'), Locale('en')]` و `locale` من الإعدادات.
- انتقالات سلسة: AnimatedSwitcher/PageTransitionsTheme، flutter_animate للـ micro-interactions (fadeIn/scale خفيف).

### Task 6 — README + تنظيف نهائي
README.md بالعربية: الوصف، الميزات، البنية، الاعتماديات وإصداراتها، طريقة التشغيل، كيف يعمل CI. + حذف أي ملفات زائدة + `git add -A` وتدقيق أن كل شيء مcommit.

## قواعد التنفيذ للـ subagents
- تكتب فقط ملفاتك المحددة. لا تعدّل ملفات مهام أخرى.
- لا `flutter` محلياً — التحقق عبر CI بعد الدمج.
- Dart نظيف: لا unused imports، أنواع صريحة، لا `dynamic` إلا عند فك JSON مع cast فوري.
- كل مهمة تنتهي بـ git commit منفصل برسالة واضحة.

</content>