// providers الإعدادات: AsyncNotifier مع دوال تحديث وحفظ
// Settings providers: AsyncNotifier with update + persist helpers

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import 'app_providers.dart';

/// حالة الإعدادات القابلة للتعديل / Editable settings state
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final getSettings = await ref.watch(getSettingsUseCaseProvider.future);
    return getSettings();
  }

  /// حفظ بعد أي تعديل — مع معالجة أخطاء وإعادة الحالة عند الفشل
  /// Persist after any change — with error handling and state revert
  Future<void> _save(AppSettings next) async {
    try {
      final saveSettings = await ref.read(saveSettingsUseCaseProvider.future);
      await saveSettings(next);
      // حدّث UI فقط بعد نجاح الحفظ الفعلي / update UI only after real success
      state = AsyncValue<AppSettings>.data(next);
    } catch (e, st) {
      // أبلغ بالفشل بدل إخفائه / surface the failure instead of swallowing it
      state = AsyncValue<AppSettings>.error(e, st);
      assert(() {
        debugPrint('Hirz: settings save failed: $e');
        return true;
      }());
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
    final Map<String, int> offsets =
        Map<String, int>.from(current.iqamahOffsets);
    offsets[prayerKey] = minutes;
    await _save(current.copyWith(iqamahOffsets: offsets));
  }

  Future<void> updateFontThickness(double thickness) async {
    final AppSettings? current = state.valueOrNull;
    if (current == null) return;
    await _save(current.copyWith(fontThickness: thickness));
  }

  Future<void> updateFontFamily(String family) async {
    final AppSettings? current = state.valueOrNull;
    if (current == null) return;
    await _save(current.copyWith(fontFamily: family));
  }

  Future<void> updateAdhanEnabled(bool enabled) async {
    final AppSettings? current = state.valueOrNull;
    if (current == null) return;
    await _save(current.copyWith(adhanEnabled: enabled));
  }
}

/// المزود الرئيسي للإعدادات / The main settings provider
final AsyncNotifierProvider<SettingsNotifier, AppSettings> settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);