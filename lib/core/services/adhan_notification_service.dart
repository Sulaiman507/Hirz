// خدمة إشعارات الأذان والإقامة / Adhan & Iqamah notification service
// flutter_local_notifications 22.3.0 — named parameters API

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/prayer_time.dart';
import '../../domain/entities/notification_settings.dart';

/// أسماء الصلوات بالعربية والإنجليزية للإشعار / Prayer names for notifications
const Map<String, Map<String, String>> kAdhanPrayerNames =
    <String, Map<String, String>>{
  'fajr': <String, String>{'ar': 'الفجر', 'en': 'Fajr'},
  'sunrise': <String, String>{'ar': 'الشروق', 'en': 'Sunrise'},
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

  // v4: معرفات القنوات — v3 كانت مستخدمة سابقًا فالتغيير يجبر قنوات نظيفة
  // v4 suffix: Android caches channels forever; new id forces clean channels
  static const String channelAdhan = 'adhan_full_v4';
  static const String channelShort = 'adhan_short_v4';
  static const String channelIqamah = 'adhan_iqamah_v4';

  /// تهيئة الخدمة + إنشاء القنوات / init + create channels
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

  /// إنشاء القنوات الثلاث / Create three notification channels
  Future<void> _createChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    // قناة الأذان الكامل — صوت المؤذن مع fullScreenIntent
    const AndroidNotificationChannel adhan = AndroidNotificationChannel(
      channelAdhan,
      'الأذان الكامل / Full Adhan',
      description: 'صوت المؤذن الكامل مع شاشة منبّه',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan_regular'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
    );

    // قناة النغمة القصيرة — إشعار عادي
    const AndroidNotificationChannel short = AndroidNotificationChannel(
      channelShort,
      'نغمة قصيرة / Short Tone',
      description: 'إشعار بنغمة قصيرة عند دخول وقت الصلاة',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('short_tone'),
      enableVibration: true,
    );

    // قناة الإقامة — صامت مع اهتزاز
    const AndroidNotificationChannel iqamah = AndroidNotificationChannel(
      channelIqamah,
      'الإقامة / Iqamah',
      description: 'تنبيه الإقامة عند بداية الصلاة',
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: true,
    );

    await android.createNotificationChannel(adhan);
    await android.createNotificationChannel(short);
    await android.createNotificationChannel(iqamah);
  }

  // ─── الأذونات ─── / ─── Permissions ───

  /// هل إذن الإشعارات ممنوع؟ / are notifications enabled at all?
  Future<bool?> notificationsEnabled() async {
    await init();
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return android?.areNotificationsEnabled();
  }

  /// طلب إذن الإشعارات (أندرويد 13+) / request POST_NOTIFICATIONS
  Future<void> requestNotificationPermission() async {
    await init();
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.requestNotificationsPermission();
    }
  }

  /// هل إذن الجدولة الدقيقة ممنوح؟ / is exact alarm permission granted?
  Future<bool?> canScheduleExact() async {
    await init();
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return android?.canScheduleExactNotifications();
  }

  /// طلب إذن الجدولة الدقيقة (يرسل لإعدادات النظام)
  Future<void> requestExactAlarm() async {
    await init();
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.requestExactAlarmsPermission();
    }
  }

  // ─── الجدولة ─── / ─── Scheduling ───

  /// جدولة أذان واحد / Schedule a single adhan
  Future<void> scheduleAdhan({
    required int id,
    required String prayerName,
    required tz.TZDateTime when,
    required bool isFajr,
    required AlertType alertType,
  }) async {
    await init();
    final String title = 'حان الآن وقت صلاة ${_prayerNameAr(prayerName)}';
    final String body = alertType == AlertType.fullAdhan
        ? 'حي على الصلاة'
        : 'وقت ${_prayerNameAr(prayerName)}';

    final String channelId = _channelFor(alertType);
    final bool fullScreen = alertType == AlertType.fullAdhan;
    final String soundName = isFajr ? 'adhan_fajr' : 'adhan_regular';

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      _channelTitle(alertType),
      importance: fullScreen ? Importance.max : Importance.high,
      priority: fullScreen ? Priority.max : Priority.high,
      category: AndroidNotificationCategory.alarm,
      sound: alertType == AlertType.silent
          ? null
          : RawResourceAndroidNotificationSound(
              alertType == AlertType.fullAdhan ? soundName : 'short_tone',
            ),
      audioAttributesUsage: fullScreen
          ? AudioAttributesUsage.alarm
          : AudioAttributesUsage.notification,
      fullScreenIntent: fullScreen,
      enableVibration: true,
      playSound: alertType != AlertType.silent,
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('Hirz: scheduled adhan id=$id prayer=$prayerName type=${alertType.name}');
    } catch (e) {
      debugPrint('Hirz: FAILED to schedule adhan id=$id: $e');
    }
  }

  /// جدولة الإقامة / Schedule iqamah notification
  Future<void> scheduleIqamah({
    required int id,
    required String prayerName,
    required tz.TZDateTime when,
  }) async {
    await init();
    final String title = 'إقامة صلاة ${_prayerNameAr(prayerName)}';
    final String body = 'الصلاة قد أقيمت — صفوف الصلاة';

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelIqamah,
      _channelTitle(AlertType.silent),
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      category: AndroidNotificationCategory.reminder,
      enableVibration: true,
      playSound: false,
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('Hirz: scheduled iqamah id=$id prayer=$prayerName');
    } catch (e) {
      debugPrint('Hirz: FAILED to schedule iqamah id=$id: $e');
    }
  }

  /// إلغاء جميع الإشعارات المجدولة / cancel all scheduled notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('Hirz: all notifications cancelled');
  }

  /// عدد الإشعارات المجمولة حاليًا / count of pending scheduled notifications
  Future<int> pendingCount() async {
    await init();
    final List<PendingNotificationRequest> pending =
        await _plugin.pendingNotificationRequests();
    return pending.length;
  }

  /// تجربة إشعار الأذان فورًا / test adhan notification immediately
  Future<void> testAdhan({required AlertType type, required bool isFajr}) async {
    await init();
    final String channelId = _channelFor(type);
    final bool fullScreen = type == AlertType.fullAdhan;
    final String soundName = isFajr ? 'adhan_fajr' : 'adhan_regular';

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      _channelTitle(type),
      importance: fullScreen ? Importance.max : Importance.high,
      priority: fullScreen ? Priority.max : Priority.high,
      category: AndroidNotificationCategory.alarm,
      sound: type == AlertType.silent
          ? null
          : RawResourceAndroidNotificationSound(
              type == AlertType.fullAdhan ? soundName : 'short_tone',
            ),
      audioAttributesUsage: fullScreen
          ? AudioAttributesUsage.alarm
          : AudioAttributesUsage.notification,
      fullScreenIntent: fullScreen,
      enableVibration: true,
      playSound: type != AlertType.silent,
    );

    await _plugin.show(
      id: isFajr ? 900100 : 900101,
      title: isFajr ? 'تجربة أذان الفجر' : 'تجربة الأذان',
      body: 'هذه تجربة لصوت الأذان',
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  /// تجربة إشعار الإقامة فورًا / test iqamah immediately
  Future<void> testIqamah() async {
    await init();
    await _plugin.show(
      id: 900102,
      title: 'تجربة إقامة الصلاة',
      body: 'الصلاة قد أقيمت',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelIqamah,
          _channelTitle(AlertType.silent),
          importance: Importance.defaultImportance,
          category: AndroidNotificationCategory.reminder,
          enableVibration: true,
          playSound: false,
        ),
      ),
    );
  }

  // ─── أدوات مساعدة ─── / ─── Helpers ───

  /// اختيار القناة حسب نوع التنبيه / pick channel by alert type
  String _channelFor(AlertType type) {
    switch (type) {
      case AlertType.fullAdhan:
        return channelAdhan;
      case AlertType.shortTone:
        return channelShort;
      case AlertType.silent:
        return channelIqamah;
    }
  }

  /// عنوان القناة حسب نوع التنبيه / channel title by alert type
  String _channelTitle(AlertType type) {
    switch (type) {
      case AlertType.fullAdhan:
        return 'الأذان الكامل / Full Adhan';
      case AlertType.shortTone:
        return 'نغمة قصيرة / Short Tone';
      case AlertType.silent:
        return 'الإقامة / Iqamah';
    }
  }

  /// اسم الصلاة بالعربي / prayer name in Arabic
  String _prayerNameAr(String key) =>
      kAdhanPrayerNames[key]?['ar'] ?? key;
}
