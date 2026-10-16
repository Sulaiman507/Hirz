// حِرز — نقطة الدخول / Hirz entry point
// ProviderScope → قراءة الإعدادات → MaterialApp مع ثيم ولغة ديناميكيين

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'core/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'domain/entities/app_settings.dart';
import 'presentation/providers/settings_providers.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // شاشة كاملة غامرة: إخفاء شريط الحالة وشريط التنقل نهائياً —
  // يظهران لحظياً فقط عند السحب من الحافة ثم يختفيان تلقائياً
  // Immersive fullscreen: hide status + navigation bars —
  // they peek on edge-swipe, then auto-hide
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  _initTimezone();
  runApp(const ProviderScope(child: HirzApp()));
}

/// تهيئة قاعدة بيانات المناطق الزمنية لحسابات المدن
/// Init the timezone DB used for city-local prayer time math
/// (الحساب يستخدم مناطق المدن صراحةً — لا يعتمد على منطقة الجهاز)
void _initTimezone() {
  tzdata.initializeTimeZones();
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
      // فشل تحميل الإعدادات: شاشة خطأ مع زر إعادة — لا تعليق أبدي
      // Settings load failure: error screen with retry — no eternal hang
      error: (Object error, StackTrace stack) => _errorSplash(ref),
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
          home: const HomeScreen(),
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

  /// شاشة خطأ بدء التشغيل مع زر إعادة المحاولة / Startup error with retry
  Widget _errorSplash(WidgetRef ref) {
    return MaterialApp(
      title: 'حِرز',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            final AppLocalizations l10n = AppLocalizations.of(context);
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(l10n.tr('error')),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(settingsProvider),
                    child: Text(l10n.tr('retry')),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
