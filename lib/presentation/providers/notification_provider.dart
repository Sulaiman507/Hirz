// مزود إشعارات الصلوات / Prayer notification provider
// يقرأ إعدادات الإشعارات ويوفر دوال التحديث

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/adhan_notification_service.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/entities/prayer_time.dart';
import '../../domain/usecases/notification_usecases.dart';
import 'app_providers.dart';
import 'settings_providers.dart';
import 'city_providers.dart';

/// مزود إعدادات الإشعارات / Notification settings notifier
class NotificationNotifier extends AsyncNotifier<NotificationSettings> {
  @override
  Future<NotificationSettings> build() async {
    final SettingsLocalDatasource ds = await ref.watch(
      settingsLocalDatasourceProvider.future,
    );
    return ds.loadNotifications();
  }

  /// حفظ الإعدادات بعد تعديل / persist after edit
  Future<void> _save(NotificationSettings next) async {
    try {
      final SettingsLocalDatasource ds = await ref.read(
        settingsLocalDatasourceProvider.future,
      );
      await ds.saveNotifications(next);
      state = AsyncValue<NotificationSettings>.data(next);
    } catch (e, st) {
      state = AsyncValue<NotificationSettings>.error(e, st);
    }
  }

  /// تفعيل/تعطيل عام / toggle master switch
  Future<void> toggleMaster(bool enabled) async {
    final NotificationSettings? current = state.valueOrNull;
    if (current == null) return;
    await _save(current.copyWith(masterEnabled: enabled));
  }

  /// تفعيل/تعطيل صلاة معينة / toggle specific prayer
  Future<void> togglePrayer(Prayer prayer, bool enabled) async {
    final NotificationSettings? current = state.valueOrNull;
    if (current == null) return;
    final Map<Prayer, PrayerNotification> prayers =
        Map<Prayer, PrayerNotification>.from(current.prayers);
    final PrayerNotification? existing = prayers[prayer];
    prayers[prayer] = PrayerNotification(
      enabled: enabled,
      type: existing?.type ?? AlertType.shortTone,
    );
    await _save(current.copyWith(prayers: prayers));
  }

  /// تغيير نوع التنبيه لصلاة / change alert type for a prayer
  Future<void> setAlertType(Prayer prayer, AlertType type) async {
    final NotificationSettings? current = state.valueOrNull;
    if (current == null) return;
    final Map<Prayer, PrayerNotification> prayers =
        Map<Prayer, PrayerNotification>.from(current.prayers);
    final PrayerNotification? existing = prayers[prayer];
    prayers[prayer] = PrayerNotification(
      enabled: existing?.enabled ?? false,
      type: type,
    );
    await _save(current.copyWith(prayers: prayers));
  }

  /// تفعيل/تعطيل الإقامة / toggle iqamah
  Future<void> toggleIqamah(bool enabled) async {
    final NotificationSettings? current = state.valueOrNull;
    if (current == null) return;
    await _save(current.copyWith(iqamahEnabled: enabled));
  }
}

/// المزود الرئيسي للإعدادات / Main notification provider
final AsyncNotifierProvider<NotificationNotifier, NotificationSettings>
notificationProvider =
    AsyncNotifierProvider<NotificationNotifier, NotificationSettings>(
  NotificationNotifier.new,
);

/// خدمة الإشعارات كـ provider / notification service provider
final Provider<AdhanNotificationService> adhanNotificationServiceProvider =
    Provider<AdhanNotificationService>(
  (Ref ref) => AdhanNotificationService.instance,
);

/// إعادة جدولة الإشعارات يدويًا / Manual reschedule
/// تُستدعى من main.dart عند فتح التطبيق أو تغيير الإعدادات
Future<int> rescheduleNotifications(WidgetRef ref) async {
  try {
    final NotificationSettings notifSettings =
        await ref.read(notificationProvider.future);
    if (!notifSettings.masterEnabled) {
      await AdhanNotificationService.instance.cancelAll();
      return 0;
    }

    // جمع 7 أيام / collect 7 days
    final List<PrayerTime> all = <PrayerTime>[];
    final getPrayerTimes = await ref.read(
      getPrayerTimesUseCaseProvider.future,
    );
    final City city = await ref.read(selectedCityProvider.future);
    final AppSettings settings = await ref.read(settingsProvider.future);
    for (int i = 0; i <= 6; i++) {
      try {
        final DailyPrayerTimes day = await getPrayerTimes(
          city: city,
          date: DateTime.now().add(Duration(days: i)),
          settings: settings,
        );
        all.addAll(day.times);
      } catch (_) {}
    }

    final ScheduleAdhansUseCase useCase = ScheduleAdhansUseCase(
      AdhanNotificationService.instance,
    );
    final ScheduleResult result = await useCase.call(
      times: all,
      settings: notifSettings,
      iqamahOffsets: settings.iqamahOffsets,
      timezoneId: city.timezoneId,
    );
    return result.scheduled;
  } catch (_) {
    return 0;
  }
}
