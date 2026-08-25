// حِرز — نقطة الدخول / Hirz entry point
// ProviderScope → قراءة الإعدادات → MaterialApp مع ثيم ولغة ديناميكيين

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'core/l10n/app_localizations.dart';
import 'core/services/adhan_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'domain/entities/app_settings.dart';
import 'domain/entities/prayer_time.dart';
import 'presentation/providers/settings_providers.dart';
import 'presentation/providers/prayer_providers.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  _initTimezone();
  runApp(const ProviderScope(child: HirzApp()));
}

/// تهيئة المنطقة الزمنية للجدولة الدقيقة / init timezone DB for exact scheduling
void _initTimezone() {
  tzdata.initializeTimeZones();
  try {
    final String localName = DateTime.now().timeZoneName;
    final Iterable<String> known = tz.timeZoneDatabase.locations.keys;
    if (known.contains(localName)) {
      tz.setLocalLocation(tz.getLocation(localName));
    }
  } catch (_) {
    // بلا setLocal تعمل TZDateTime.from بتوقيت UTC — الأذان قد ينحرف
    // without setLocal, conversions fall back to UTC — adhan may drift
  }
}

/// التطبيق الجذري: يقرأ الإعدادات ويطبّق اللغة والثيم
/// Root app: reads settings, applies locale + theme
class HirzApp extends ConsumerWidget {
  const HirzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppSettings> settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => _splash(),
      error: (Object error, StackTrace stack) => _splash(),
      data: (AppSettings settings) {
        // الخط والسماكة من الإعدادات تُمرَّر فعلياً إلى MaterialApp
        // Font family + thickness from settings actually reach MaterialApp
        // (MaterialApp يتحرك بين الفاتح والداكن داخلياً — لا حاجة لـ AnimatedTheme)
        return MaterialApp(
          title: 'حِرز',
          debugShowCheckedModeBanner: false,
          locale: Locale(settings.languageCode),
          supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(
            fontFamily: settings.fontFamily,
            fontThickness: settings.fontThickness,
          ),
          darkTheme: AppTheme.dark(
            fontFamily: settings.fontFamily,
            fontThickness: settings.fontThickness,
          ),
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const _AdhanScheduler(child: HomeScreen()),
        );
      },
    );
  }

  /// شاشة بسيطة أثناء تحميل الإعدادات / Simple splash while settings load
  Widget _splash() {
    return MaterialApp(
      title: 'حِرز',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

/// مستمع الجدولة: يعيد جدولة الأذان عند أي تغيير (مدينة/إعدادات/تفعيل)
/// Scheduling listener: reschedules the adhan on any relevant change
class _AdhanScheduler extends ConsumerStatefulWidget {
  const _AdhanScheduler({required this.child});

  final Widget child;

  @override
  ConsumerState<_AdhanScheduler> createState() => _AdhanSchedulerState();
}

class _AdhanSchedulerState extends ConsumerState<_AdhanScheduler> {
  @override
  void initState() {
    super.initState();
    // جدولة أولى بعد أول إطار ثم استماع دائم للتغييرات
    WidgetsBinding.instance.addPostFrameCallback((_) => _reschedule());
    ref.listenManual(settingsProvider, (_, __) => _reschedule());
    ref.listenManual(prayerTimesProvider, (_, __) => _reschedule());
    ref.listenManual(tomorrowTimesProvider, (_, __) => _reschedule());
  }

  /// يلغي الكل إذا كان معطلاً، وإلا يجدول اليوم + الغد
  void _reschedule() {
    final AppSettings? settings = ref.read(settingsProvider).valueOrNull;
    final AdhanNotificationService service = AdhanNotificationService.instance;
    if (settings == null || !settings.adhanEnabled) {
      service.cancelAll();
      return;
    }
    Future<void>(() async {
      try {
        final DailyPrayerTimes today =
            await ref.read(prayerTimesProvider.future);
        final List<PrayerTime> all = List<PrayerTime>.of(today.times);
        try {
          final DailyPrayerTimes tomorrow =
              await ref.read(tomorrowTimesProvider.future);
          all.addAll(tomorrow.times);
        } catch (_) {
          // الغد اختياري — جدولة اليوم وحدها تكفي مؤقتاً
        }
        await service.scheduleAdhan(all);
      } catch (_) {
        // لا نعطل التطبيق عند فشل الجدولة
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}