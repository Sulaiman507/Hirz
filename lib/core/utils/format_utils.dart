// أدوات التنسيق العامة / Shared formatting utilities

/// تطبيع النص العربي للبحث: توحيد الهمزات والألف والتاء المربوطة
/// والألف المقصورة — "إسطنبول" تطابق "اسطنبول"، و"القاهرة" تطابق "القاهره"
/// Normalize Arabic text for search: unify hamza/alef variants, ta-marbuta,
/// and alef-maqsura — "إسطنبول" matches "اسطنبول", "القاهرة" matches "القاهره"
String normalizeArabicSearch(String input) {
  return input
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي');
}

/// تطبيع مدخل رقمي للوحة مفاتيح عربية: أرقام عربية/فارسية ← لاتينية،
/// والفاصلة العشرية العربية ← نقطة، مع إسقاط فاصل الآلاف
/// Normalize numeric input from Arabic keyboards: Arabic-Indic/Persian
/// digits → ASCII, Arabic decimal separator → dot, drop thousands separator
String normalizeNumericInput(String input) {
  const String arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  const String persianIndic = '۰۱۲۳۴۵۶۷۸۹';
  String out = input;
  for (int i = 0; i < 10; i++) {
    out = out.replaceAll(arabicIndic[i], '$i');
    out = out.replaceAll(persianIndic[i], '$i');
  }
  return out
      .replaceAll('٫', '.') // فاصلة عشرية عربية / Arabic decimal separator
      .replaceAll('٬', '') // فاصل آلاف عربي / Arabic thousands separator
      .replaceAll(',', '.');
}

/// تنسيق إزاحة المنطقة الزمنية بشكل نظيف / Tidy UTC offset label
///
/// أمثلة / examples:
/// - `3.0`   → `UTC+3`
/// - `-6.0`  → `UTC-6`
/// - `3.5`   → `UTC+3.5`
/// - `5.75`  → `UTC+5.75` (نيبال / Nepal)
String formatUtcOffset(double hours) {
  // تقريب لخانتين لإزالة ضجيج الفاصلة العائمة ثم عرض بدون أصفار زائدة
  // Round to 2dp to shed float noise, render without trailing zeros
  final double rounded = double.parse(hours.toStringAsFixed(2));
  final bool negative = rounded < 0;
  final double magnitude = rounded.abs();
  final String magnitudeLabel = magnitude == magnitude.roundToDouble()
      ? magnitude.round().toString()
      : magnitude.toString();
  return 'UTC${negative ? '-' : '+'}$magnitudeLabel';
}
