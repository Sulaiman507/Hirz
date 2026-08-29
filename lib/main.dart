// حِرز — نقطة الدخول / Hirz entry point
// ProviderScope → قراءة الإعدادات → MaterialApp مع ثيم ولغة ديناميكيين

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'core/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'domain/entities/app_settings.dart';
import 'presentation/providers/settings_providers.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/city_providers.dart';
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
          home: const _NotificationScheduler(child: HomeScreen()),
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
      home: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

/// مستمع الجدولة: يعيد جدولة الإشعارات عند أي تغيير (مدينة/إعدادات/تفعيل)
/// Scheduling listener: reschedules notifications on any relevant change
class _NotificationScheduler extends ConsumerStatefulWidget {
  const _NotificationScheduler({required this.child});

  final Widget child;

  @override
  ConsumerState<_NotificationScheduler> createState() =>
      _NotificationSchedulerState();
}

class _NotificationSchedulerState extends ConsumerState<_NotificationScheduler> {
  @override
  void initState() {
    super.initState();
    // جدولة أولى بعد أول إطار
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(autoSchedulingProvider.notifier).reschedule();
    });
    // استماع دائم للتغييرات
    ref.listenManual(settingsProvider, (_, __) {
      ref.read(autoSchedulingProvider.notifier).reschedule();
    });
    ref.listenManual(notificationProvider, (_, __) {
      ref.read(autoSchedulingProvider.notifier).reschedule();
    });
    ref.listenManual(selectedCityProvider, (_, __) {
      ref.read(autoSchedulingProvider.notifier).reschedule();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
