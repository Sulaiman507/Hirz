// بطاقة صلاة واحدة: الاسم + الأذان + الإقامة / Prayer card: name + adhan + iqamah

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_formatter.dart';
import '../../core/widgets/glass_card.dart';
import '../../domain/entities/prayer_time.dart';

/// بطاقة صلاة مع تمييز الصلاة القادمة / Prayer card, highlights the next prayer
class PrayerCard extends StatelessWidget {
  final PrayerTime prayerTime;
  final bool isNext;
  final bool use24Hour;
  final String languageCode;

  const PrayerCard({
    super.key,
    required this.prayerTime,
    required this.isNext,
    required this.use24Hour,
    required this.languageCode,
  });

  /// مفتاح ترجمة اسم الصلاة / Localization key for this prayer
  String _prayerKey() => prayerTime.prayer.name; // fajr..isha

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: <Widget>[
          // اسم الصلاة / Prayer name
          Expanded(
            child: Text(
              l10n.tr(_prayerKey()),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                    color: isNext ? scheme.primary : scheme.onSurface,
                  ),
            ),
          ),
          // الأذان / Adhan time
          Text(
            formatTime(prayerTime.time,
                use24Hour: use24Hour, languageCode: languageCode),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isNext ? AppColors.goldBright : scheme.onSurface,
                  fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                ),
          ),
          const SizedBox(width: 16),
          // الإقامة / Iqamah time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                l10n.tr('iqamah'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              Text(
                formatTime(prayerTime.iqamahTime,
                    use24Hour: use24Hour, languageCode: languageCode),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.8),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}