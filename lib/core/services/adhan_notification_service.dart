// خدمة إشعارات الأذان — قناتان بصوت المؤذن المدمج
// Adhan notification service — two channels with bundled muezzin audio

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/prayer_time.dart';

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
    await _plugin.initialize(const InitializationSettings(android: android));
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

  /// جدولة أذانات يوم كامل (اليوم + الغد) بعد إلغاء القديمة
  /// Schedule a full day of adhans (today + tomorrow) after cancelling old ones
  Future<void> scheduleAdhan(List<PrayerTime> times) async {
    await init();
    await cancelAll();
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    for (final PrayerTime pt in times) {
      if (pt.prayer == Prayer.sunrise)
        continue; // الشروق ليس أذاناً / no adhan at sunrise
      final tz.TZDateTime when = tz.TZDateTime.from(pt.time, tz.local);
      if (!when.isAfter(now)) continue; // فات وقته / already passed
      final bool isFajr = pt.prayer == Prayer.fajr;
      final String name =
          kAdhanPrayerNames[pt.prayer.name]?['ar'] ?? pt.prayer.name;
      await _plugin.zonedSchedule(
        pt.prayer.index * 10 + when.day, // معرف مستقر لكل صلاة/يوم
        'حان الآن وقت صلاة $name',
        'حي على الصلاة',
        when,
        NotificationDetails(
          android: AndroidNotificationDetails(
            isFajr ? channelFajr : channelRegular,
            isFajr ? 'أذان الفجر / Fajr Adhan' : 'الأذان / Adhan',
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.alarm,
            // صوت في الإشعار نفسه كطبقة ثانية فوق إعداد القناة
            sound: RawResourceAndroidNotificationSound(
              isFajr ? 'adhan_fajr' : 'adhan_regular',
            ),
            audioAttributesUsage: AudioAttributesUsage.alarm,
            fullScreenIntent: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// تجربة الأذان فوراً — تشغيل إشعار على القناة المطلوبة
  /// Test the adhan immediately — fires a notification on the given channel
  Future<void> testAdhan({required bool fajr}) async {
    await init();
    await _plugin.show(
      fajr ? 900001 : 900002,
      fajr ? 'تجربة أذان الفجر' : 'تجربة الأذان',
      'هذه تجربة لصوت الأذان المدمج',
      NotificationDetails(
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

  /// إلغاء كل الأذانات المجدولة / cancel all scheduled adhans
  Future<void> cancelAll() => _plugin.cancelAll();

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

  /// هل إذن الجدولة الدقيقة ممنوح؟ / is exact alarm permission granted?
  /// null = غير معروف على هذه المنصة / unknown on this platform
  Future<bool?> exactAlarmGranted() async {
    await init();
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return android?.checkExactNotificationPermission();
  }
}
