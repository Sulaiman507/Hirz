// رأس التاريخ: هجري + ميلادي / Date header: Hijri + Gregorian

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/hijri_date.dart';

/// عرض التاريخ الهجري والميلادي معاً / Shows both calendars
class DateHeader extends StatelessWidget {
  final DateTime date;
  final String languageCode;

  const DateHeader({
    super.key,
    required this.date,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    // الهجري / Hijri
    final HijriDate hijri = hijriFromDate(date);
    final String hijriText = formatHijri(hijri, languageCode);

    // الميلادي: اسم اليوم + رقم + اسم الشهر / Gregorian: day name + number + month
    final List<String> weekDays = l10n.trList('weekDays');
    final List<String> months = l10n.trList('gregorianMonths');
    final String gregorianText = languageCode == 'ar'
        ? '${weekDays[date.weekday % 7]} ${date.day} ${months[date.month - 1]} ${date.year}'
        : '${weekDays[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}, ${date.year}';

    return Column(
      children: <Widget>[
        Text(
          hijriText,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          gregorianText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }
}