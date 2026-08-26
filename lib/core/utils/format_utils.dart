// أدوات التنسيق العامة / Shared formatting utilities

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
