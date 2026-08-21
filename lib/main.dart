// حِرز — نقطة الدخول / Hirz entry point
// ProviderScope → قراءة الإعدادات → MaterialApp مع ثيم ولغة ديناميكيين

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'domain/entities/app_settings.dart';
import 'presentation/providers/settings_providers.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: HirzApp()));
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
        final ThemeData theme =
            settings.isDarkMode ? AppTheme.dark() : AppTheme.light();

        // AnimatedTheme لانتقال سلس بين الفاتح والداكن
        // AnimatedTheme for smooth light/dark transition
        return AnimatedTheme(
          data: theme,
          duration: const Duration(milliseconds: 350),
          child: MaterialApp(
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
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode:
                settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomeScreen(),
          ),
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