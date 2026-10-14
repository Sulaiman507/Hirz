// providers الإعدادات: AsyncNotifier مع دوال تحديث وحفظ
// Settings providers: AsyncNotifier with update + persist helpers

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import 'app_providers.dart';

/// طباعة تشخيصية في وضع التطوير فقط / debug-only logging
void _debugLog(String message) {
  if (kDebugMode) debugPrint(message);
}

/// حالة الإعدادات القابلة للتعديل
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  /// مؤقت تأجيل حفظ سماكة الخط — يمنع الكتابة للقرص مع كل حركة للسلايدر
  /// Debounce for font-thickness persistence — avoids disk writes per slider tick
  Timer? _thicknessPersistTimer;

  @override
  Future<AppSettings> build() async {
    final getSettings = await ref.watch(getSettingsUseCaseProvider.future);
    return getSettings();
  }

  /// كتابة الإعدادات للقرص دون لمس الحالة / persist without touching state
  Future<void> _persist(AppSettings settings) async {
    final saveSettings = await ref.read(saveSettingsUseCaseProvider.future);
    await saveSettings(settings);
  }

  Future<void> _save(AppSettings next) async {
    try {
      await _persist(next);
      state = AsyncValue<AppSettings>.data(next);
    } catch (e) {
      // الفشل يُبقي الإعدادات القديمة — لا نمحو واجهة التطبيق بخطأ
      // On failure keep the old settings — never blank the app on an error
      _debugLog('Hirz: settings save failed: $e');
    }
  }

  Future<void> updateLanguage(String languageCode) async {
    final AppSettings? current = state.valueOrNull;
    if (current == null) return;
    await _save(current.copyWith(languageCode: languageCode));
  }

  Future<void> updateTheme(bool isDarkMode) async {
    final AppSettings? current = state.valueOrNull;
    if (current == null) return;
    await _save(current.copyWith(isDarkMode: isDarkMode));
  }

  Future<void> updateMethod(CalculationMethod method) async {
    final AppSettings? current = state.valueOrNull;
    if (current == null) return;
    await _save(current.copyWith(method: method));
  }

  Future<void> updateMadhab(Madhab madhab) async {
    final AppSettings? current = state.valueOrNull;
    if (current == null) return;
    await _save(current.copyWith(madhab: madhab));
  }

  Future<void> updateTimeFormat(bool use24HourFormat) async {
    final AppSettings? current = state.valueOrNull;
    if (current == null) return;
    await _save(current.copyWith(use24HourFormat: use24HourFormat));
  }

  Future<void> updateIqamahOffset(String prayerKey, int minutes) async {
    final AppSettings? current = state.valueOrNull;
    if (current == null) return;
    final Map<String, int> offsets = Map<String, int>.from(
      current.iqamahOffsets,
    );
    offsets[prayerKey] = minutes;
    await _save(current.copyWith(iqamahOffsets: offsets));
  }

  Future<void> updateFontThickness(double thickness) async {
    final AppSettings? current = state.valueOrNull;
    if (current == null) return;
    // معاينة حية فورية + حفظ مؤجل 600ms بعد توقف السحب
    // Instant live preview + persist 600ms after the drag settles
    state = AsyncValue<AppSettings>.data(
      current.copyWith(fontThickness: thickness),
    );
    _thicknessPersistTimer?.cancel();
    _thicknessPersistTimer = Timer(const Duration(milliseconds: 600), () async {
      final AppSettings? latest = state.valueOrNull;
      if (latest == null) return;
      try {
        await _persist(latest);
      } catch (e) {
        _debugLog('Hirz: font thickness persist failed: $e');
      }
    });
  }

  Future<void> updateFontFamily(String family) async {
    final AppSettings? current = state.valueOrNull;
    if (current == null) return;
    await _save(current.copyWith(fontFamily: family));
  }
}

/// المزود الرئيسي للإعدادات
final AsyncNotifierProvider<SettingsNotifier, AppSettings> settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
