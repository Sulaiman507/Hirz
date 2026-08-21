// التقويم الهجري الجدولي (الكويتي) — دوال نقية بدون Flutter
// Tabular (civil/Kuwaiti) Islamic calendar — pure Dart, no Flutter

/// تاريخ هجري واحد / A single Hijri date
class HijriDate {
  final int year;
  final int month; // 1..12
  final int day; // 1..30

  const HijriDate(this.year, this.month, this.day);

  @override
  String toString() => '$year/$month/$day';

  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

/// أسماء الأشهر الهجرية بالعربية / Hijri month names (Arabic)
const List<String> hijriMonthsAr = <String>[
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الآخر',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];

/// أسماء الأشهر الهجرية بالإنجليزية / Hijri month names (English)
const List<String> hijriMonthsEn = <String>[
  'Muharram',
  'Safar',
  'Rabi I',
  'Rabi II',
  'Jumada I',
  'Jumada II',
  'Rajab',
  'Sha\'ban',
  'Ramadan',
  'Shawwal',
  'Dhul-Qi\'dah',
  'Dhul-Hijjah',
];

/// Epoch: 16 يوليو 622م (يوليوسي) = يوم يوليوسي 1948440
/// Civil epoch: 16 July 622 CE (Julian) = JD 1948440
const int _islamicEpoch = 1948440;

/// تحويل ميلادي → يوم يوليوسي / Gregorian date to Julian Day Number
int _gregorianToJd(int year, int month, int day) {
  final int a = (14 - month) ~/ 12;
  final int y = year + 4800 - a;
  final int m = month + 12 * a - 3;
  return day +
      (153 * m + 2) ~/ 5 +
      365 * y +
      y ~/ 4 -
      y ~/ 100 +
      y ~/ 400 -
      32045;
}

/// تحويل هجري → يوم يوليوسي / Hijri date to Julian Day Number
int _islamicToJd(int year, int month, int day) {
  return day +
      (29.5 * (month - 1)).ceil() +
      (year - 1) * 354 +
      (3 + 11 * year) ~/ 30 +
      _islamicEpoch -
      1;
}

/// تحويل تاريخ ميلادي إلى هجري (جدولي) / Convert Gregorian to Hijri (tabular)
HijriDate hijriFromDate(DateTime gregorian) {
  final int jd = _gregorianToJd(gregorian.year, gregorian.month, gregorian.day);

  final int year = (30 * (jd - _islamicEpoch) + 10646) ~/ 10631;

  int month =
      ((jd - (29 + _islamicToJd(year, 1, 1))) / 29.5).ceil() + 1;
  if (month < 1) month = 1;
  if (month > 12) month = 12;

  final int day = jd - _islamicToJd(year, month, 1) + 1;
  return HijriDate(year, month, day);
}

/// تنسيق التاريخ الهجري حسب اللغة / Format a Hijri date per language
/// مثال / e.g. ar: "١ شوال ١٤٤٥هـ" (الأرقام لاتينية هنا للوضوح)
String formatHijri(HijriDate date, String languageCode) {
  final List<String> months =
      languageCode == 'ar' ? hijriMonthsAr : hijriMonthsEn;
  final String monthName = months[date.month - 1];
  if (languageCode == 'ar') {
    return '${date.day} $monthName ${date.year}هـ';
  }
  return '$monthName ${date.day}, ${date.year} AH';
}