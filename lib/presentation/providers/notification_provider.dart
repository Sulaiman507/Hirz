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
import 'prayer_providers.dart';
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

/// حالة الجدولة / scheduling state
class SchedulingState {
  final bool isScheduling;
  final int scheduled;
  final int failed;
  final bool exactAlarmGranted;

  const SchedulingState({
    this.isScheduling = false,
    this.scheduled = 0,
    this.failed = 0,
    this.exactAlarmGranted = false,
  });

  SchedulingState copyWith({
    bool? isScheduling,
    int? scheduled,
    int? failed,
    bool? exactAlarmGranted,
  }) {
    return SchedulingState(
      isScheduling: isScheduling ?? this.isScheduling,
      scheduled: scheduled ?? this.scheduled,
      failed: failed ?? this.failed,
      exactAlarmGranted: exactAlarmGranted ?? this.exactAlarmGranted,
    );
  }
}

/// مزود الجدولة التلقائية / Auto-scheduling notifier
class AutoSchedulingNotifier extends StateNotifier<SchedulingState> {
  AutoSchedulingNotifier(this._ref) : super(const SchedulingState()) {
    // إعادة الجدولة عند أي تغيير / reschedule on any change
    _ref.listen(settingsProvider, (_, __) => _schedule());
    _ref.listen(prayerTimesProvider, (_, __) => _schedule());
    _ref.listen(tomorrowTimesProvider, (_, __) => _schedule());
    _ref.listen(notificationProvider, (_, __) => _schedule());
    _ref.listen(selectedCityProvider, (_, __) => _schedule());
  }

  final Ref _ref;

  /// إعادة الجدولة يدويًا (من main.dart) / manual reschedule (from main.dart)
  void reschedule() => _schedule();

  Future<void> _schedule() async {
    state = state.copyWith(isScheduling: true);
    try {
      final NotificationSettings notifSettings =
          await _ref.read(notificationProvider.future);
      if (!notifSettings.masterEnabled) {
        await AdhanNotificationService.instance.cancelAll();
        state = const SchedulingState();
        return;
      }

      // جمع 7 أيام / collect 7 days
      final List<PrayerTime> all = <PrayerTime>[];
      final getPrayerTimes = await _ref.read(
        getPrayerTimesUseCaseProvider.future,
      );
      final City city = await _ref.read(selectedCityProvider.future);
      final AppSettings settings = await _ref.read(settingsProvider.future);
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
      state = SchedulingState(
        scheduled: result.scheduled,
        failed: result.failed,
        exactAlarmGranted: result.exactAlarmGranted,
      );
    } catch (_) {
      state = const SchedulingState();
    }
  }
}

/// مزود الجدولة التلقائية / Auto-scheduling provider
final StateNotifierProvider<AutoSchedulingNotifier, SchedulingState>
autoSchedulingProvider =
    StateNotifierProvider<AutoSchedulingNotifier, SchedulingState>(
  (Ref ref) => AutoSchedulingNotifier(ref),
);
