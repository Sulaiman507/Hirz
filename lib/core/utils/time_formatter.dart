// تنسيق الوقت 12/24 ساعة / Time formatting: 12h/24h per settings

/// تنسيق DateTime كنص حسب الإعدادات
/// Format a DateTime as text per user settings
String formatTime(
  DateTime time, {
  required bool use24Hour,
  required String languageCode,
}) {
  final int hour24 = time.hour;
  final String minute = time.minute.toString().padLeft(2, '0');

  if (use24Hour) {
    final String hour = hour24.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  final bool isAM = hour24 < 12;
  final int hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final String period = languageCode == 'ar'
      ? (isAM ? 'ص' : 'م')
      : (isAM ? 'AM' : 'PM');
  return '$hour12:$minute $period';
}

/// تنسيق مدة متبقية كـ HH:MM:SS / Format remaining duration as HH:MM:SS
String formatDuration(Duration duration) {
  final int hours = duration.inHours;
  final int minutes = duration.inMinutes % 60;
  final int seconds = duration.inSeconds % 60;
  final String h = hours.toString().padLeft(2, '0');
  final String m = minutes.toString().padLeft(2, '0');
  final String s = seconds.toString().padLeft(2, '0');
  return '$h:$m:$s';
}
