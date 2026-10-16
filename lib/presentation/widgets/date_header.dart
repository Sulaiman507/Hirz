// رأس التاريخ: هجري + ميلادي / Date header: Hijri + Gregorian

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/hijri_date.dart';

/// عرض التاريخ الهجري والميلادي معاً / Shows both calendars
class DateHeader extends StatelessWidget {
  final DateTime date;
  final String languageCode;

  const DateHeader({super.key, required this.date, required this.languageCode});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    // الهجري / Hijri
    final HijriDate hijri = hijriFromDate(date);
    final String hijriText = formatHijri(hijri, languageCode);

    // الميلادي: اسم اليوم + رقم + اسم الشهر / Gregorian: day name + number + month
    // حماية من فهرسة قوائم ناقصة (أصول تالفة) — لا RangeError
    // Guard against missing lists (corrupt assets) — no RangeError
    final List<String> weekDays = l10n.trList('weekDays');
    final List<String> months = l10n.trList('gregorianMonths');
    final String weekDay = weekDays.isEmpty
        ? ''
        : weekDays[date.weekday % 7];
    final String month = months.isEmpty || date.month > months.length
        ? ''
        : months[date.month - 1];
    final String gregorianText = languageCode == 'ar'
        ? '$weekDay ${date.day} $month ${date.year}'
        : '$weekDay, $month ${date.day}, ${date.year}';

    return Column(
      children: <Widget>[
        Text(
          hijriText,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          gregorianText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
