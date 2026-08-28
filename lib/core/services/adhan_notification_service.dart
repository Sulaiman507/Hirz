// خدمة إشعارات الأذان — قناتان بصوت المؤذن المدمج
// Adhan notification service — two channels with bundled muezzin audio

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/prayer_time.dart';
import '../../domain/entities/app_settings.dart';

/// أسماء الصلوات بالعربية والإنجليزية للإشعار / Prayer names for the notification
const Map<String, Map<String, String>> kAdhanPrayerNames =
    <String, Map<String, String>>{
      'fajr': <String, String>{'ar': 'الفجر', 'en': 'Fajr'},
      'dhuhr': <String, String>{'ar': 'الظهر', 'en': 'Dhuhr'},
      'asr': <String, String>{'ar': 'العصر', 'en': 'Asr'},
      'maghrib': <String, String>{'ar': 'المغرب', 'en': 'Maghrib'},
      'isha': <String, String>{'ar': 'العشاء', 'en': 'Isha'},
    };

class AdhanNotificationService {
  AdhanNotificationService._();

  static final AdhanNotificationService instance = AdhanNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // v3: أندرويد يخزّن القنوات القديمة ولا يحدّثها ولا يمسحها — معرف جديد يجبر قنوات نظيفة
  // v3 suffix: Android caches channels forever; a new id forces clean channels
  static const String channelRegular = 'adhan_regular_v3';
  static const String channelFajr = 'adhan_fajr_v3';

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const AndroidInitializationSettings android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (_) {},
    );
    await _createChannels();
    _initialized = true;
  }

  /// القناتان بصوتي الأذان من res/raw — تُنسخ في الـ workflow
  /// Both channels use adhan audio from res/raw — copied by the CI workflow
  Future<void> _createChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    const AndroidNotificationChannel regular = AndroidNotificationChannel(
      channelRegular,
      'الأذان / Adhan',
      description: 'تنبيه أذان عند دخول وقت الصلاة',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan_regular'),
      // alarm usage: مستوى صوت المنبه ويتجاوز كتم الوسائط
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
    );
    const AndroidNotificationChannel fajr = AndroidNotificationChannel(
      channelFajr,
      'أذان الفجر / Fajr Adhan',
      description: 'أذان الفجر بنسخته الخاصة',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan_fajr'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
    );
    await android.createNotificationChannel(regular);
    await android.createNotificationChannel(fajr);
  }

  /// جدولة أذانات 7 أيام قادمة بعد إلغاء القديمة — يقاوم إعادة تشغيل الجهاز
  /// Schedule a week of adhans after cancelling old ones — survives reboots
  Future<void> scheduleAdhan(
    List<PrayerTime> times, {
    String? timezoneId,
  }) async {
    await init();
    await cancelAll();
    final tz.Location location = timezoneId != null && timezoneId.isNotEmpty
        ? tz.getLocation(timezoneId)
        : tz.local;
    final tz.TZDateTime now = tz.TZDateTime.now(location);
    int scheduled = 0;
    for (final PrayerTime pt in times) {
      if (pt.prayer == Prayer.sunrise) continue;
      final tz.TZDateTime when = tz.TZDateTime.from(pt.time, location);
      if (!when.isAfter(now)) continue;
      try {
        await scheduleOne(
          _stableId(pt.prayer, when),
          'حان الآن وقت صلاة ${_prayerNameAr(pt)}',
          'حي على الصلاة',
          when,
          pt.prayer == Prayer.fajr,
        );
        scheduled++;
      } catch (e) {
        debugPrint('Hirz: failed to schedule ${pt.prayer.name}: $e');
      }
    }
    debugPrint('Hirz: scheduled $scheduled adhans');
  }

  String _prayerNameAr(PrayerTime pt) =>
      kAdhanPrayerNames[pt.prayer.name]?['ar'] ?? pt.prayer.name;

  /// معرف مستقر: يوم-شه-سنة + الصلاة / stable id: date + prayer
  static int _stableId(Prayer prayer, tz.TZDateTime when) =>
      prayer.index * 100000 + when.year * 400 + when.month * 31 + when.day;

  /// تجربة الجدولة الفعلية — يضيف إشعار بعد دقيقة لاختبار مسار الجدولة
  /// Test scheduled path — schedules a notification 1 minute from now
  Future<bool> testScheduleOnce() async {
    await init();
    try {
      await requireExactAlarm();
    } on StateError {
      debugPrint('Hirz: testScheduleOnce blocked — exact alarm not granted');
      return false;
    } catch (_) {}
    try {
      final tz.Location location = tz.local;
      final tz.TZDateTime now = tz.TZDateTime.now(location);
      final tz.TZDateTime when = now.add(const Duration(minutes: 1));
      final int id = DateTime.now().millisecondsSinceEpoch % 100000;
      debugPrint(
        'Hirz: testScheduleOnce now=$now when=$when location=${location.name}',
      );
      await scheduleOne(
        id,
        'اختبار جدولة الأذان',
        'هذا إشعار تجريبي بعد دقيقة — لو وصلت فالجدولة شغالة',
        when,
        false,
      );
      final pending = await pendingCount();
      debugPrint('Hirz: testScheduleOnce OK id=$id pendingNow=$pending');
      return true;
    } catch (e) {
      debugPrint('Hirz: testScheduleOnce FAILED: $e');
      return false;
    }
  }

  /// تجربة الأذان فوراً — تشغيل إشعار على القناة المطلوبة
  /// Test the adhan immediately — fires a notification on the given channel
  Future<void> testAdhan({required bool fajr}) async {
    await init();
    await _plugin.show(
      id: fajr ? 900001 : 900002,
      title: fajr ? 'تجربة أذان الفجر' : 'تجربة الأذان',
      body: 'هذه تجربة لصوت الأذان المدمج',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          fajr ? channelFajr : channelRegular,
          fajr ? 'أذان الفجر / Fajr Adhan' : 'الأذان / Adhan',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          sound: RawResourceAndroidNotificationSound(
            fajr ? 'adhan_fajr' : 'adhan_regular',
          ),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          fullScreenIntent: true,
        ),
      ),
    );
  }

  /// جدولة أذان واحد بمستوى صوت محدد — قناة ديناميكية لكل مستوى
  /// Schedule one adhan with volume via per-level dynamic channels
  /// (أندرويد لا يدعم ضبط الصوت لكل إشعار؛ القناة هي وحدة التحكم)
  Future<void> scheduleOne(
    int id,
    String title,
    String body,
    tz.TZDateTime when,
    bool isFajr,
  ) async {
    final String channelId = isFajr ? channelFajr : channelRegular;

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'الأذان / Adhan',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          sound: RawResourceAndroidNotificationSound(
            isFajr ? 'adhan_fajr' : 'adhan_regular',
          ),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          fullScreenIntent: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// إلغاء كل الأذانات المجدولة / cancel all scheduled adhans
  Future<void> cancelAll() => _plugin.cancelAll();

  /// عدد الأذانات المنتظرة حالياً — للتشخيص في الإعدادات
  /// count of pending scheduled notifications — for diagnostics UI
  Future<int> pendingCount() async {
    await init();
    final List<PendingNotificationRequest> pending = await _plugin
        .pendingNotificationRequests();
    return pending.length;
  }

  /// هل إذن الإشعارات نفسه ممنوح؟ / are notifications enabled at all?
  Future<bool?> notificationsEnabled() async {
    await init();
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return android?.areNotificationsEnabled();
  }

  /// طلب إذن الإشعارات (أندرويد 13+) / request POST_NOTIFICATIONS (Android 13+)
  Future<void> ensurePermission() async {
    await init();
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.requestNotificationsPermission();
      // إذن المنبه الدقيق مطلوب للجدولة على أندرويد 14+ — غير ممنوح تلقائياً
      // exact alarm permission required for scheduling on Android 14+
      await android.requestExactAlarmsPermission();
    }
  }

  /// يتحقق من إذن الجدولة الدقيقة — يرمي خطأ واضح إذا غير مفعّل
  /// Checks exact-alarm permission; throws if not granted so UI can react
  Future<void> requireExactAlarm() async {
    await init();
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    final bool? granted = await android.canScheduleExactNotifications();
    if (granted != true) {
      throw StateError('EXACT_ALARM_NOT_GRANTED');
    }
  }

  /// هل إذن الجدولة الدقيقة ممنوح؟ / is exact alarm permission granted?
  /// null = غير معروف على هذه المنصة / unknown on this platform
  Future<bool?> exactAlarmGranted() async {
    await init();
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return android?.canScheduleExactNotifications();
  }
}
