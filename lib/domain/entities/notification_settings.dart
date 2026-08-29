// إعدادات إشعارات الصلوات / Prayer notification settings
// كيان مستقل يُحفظ مع AppSettings لكنه منفصل منطقيًا

import 'prayer_time.dart'; // Prayer enum

/// نوع التنبيه لكل صلاة / Alert type per prayer
enum AlertType {
  fullAdhan, // أذان كامل: شاشة كاملة + صوت المؤذن
  shortTone, // نغمة قصيرة: إشعار عادي مع صوت قصير
  silent, // صامت: اهتزاز فقط بدون صوت
}

/// إعدادات تنبيه صلاة واحدة / Single prayer notification config
class PrayerNotification {
  final bool enabled; // تفعيل لهذه الصلاة
  final AlertType type; // نوع التنبيه

  const PrayerNotification({
    required this.enabled,
    this.type = AlertType.shortTone,
  });

  PrayerNotification copyWith({
    bool? enabled,
    AlertType? type,
  }) {
    return PrayerNotification(
      enabled: enabled ?? this.enabled,
      type: type ?? this.type,
    );
  }

  /// تحويل من/إلى نص للتخزين / serialize for storage
  String storeKey() => '${enabled ? '1' : '0'}_${type.name}';

  static PrayerNotification load(String key, {bool fallbackEnabled = true}) {
    final List<String> parts = key.split('_');
    if (parts.length != 2) {
      return PrayerNotification(enabled: fallbackEnabled);
    }
    return PrayerNotification(
      enabled: parts[0] == '1',
      type: AlertType.values.firstWhere(
        (AlertType t) => t.name == parts[1],
        orElse: () => AlertType.shortTone,
      ),
    );
  }
}

/// إعدادات الإشعارات الكاملة / Full notification settings
class NotificationSettings {
  final bool masterEnabled; // تفعيل عام لكل الإشعارات
  final Map<Prayer, PrayerNotification> prayers; // إعدادات كل صلاة
  final bool iqamahEnabled; // تنبيه الإقامة اختياري

  const NotificationSettings({
    this.masterEnabled = false,
    this.iqamahEnabled = false,
    required this.prayers,
  });

  /// إعدادات افتراضية: كلها مطفأة / defaults: everything off
  factory NotificationSettings.defaults() {
    final Map<Prayer, PrayerNotification> map =
        <Prayer, PrayerNotification>{};
    for (final Prayer prayer in Prayer.values) {
      map[prayer] = const PrayerNotification(enabled: false);
    }
    return NotificationSettings(
      masterEnabled: false,
      iqamahEnabled: false,
      prayers: map,
    );
  }

  NotificationSettings copyWith({
    bool? masterEnabled,
    bool? iqamahEnabled,
    Map<Prayer, PrayerNotification>? prayers,
  }) {
    return NotificationSettings(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      iqamahEnabled: iqamahEnabled ?? this.iqamahEnabled,
      prayers: prayers ?? this.prayers,
    );
  }
}
