// بطاقة صلاة واحدة / Prayer card
// بلا تمييز لوني — شارتان ذهبيتان: "الحالية" (بنص متلألئ على بيج فاتح)
// و"القادمة". باقي البطاقات نظيفة بلا شارات.
// No color highlight — two gold badges: "current" (shimmer text on light
// beige) and "next". All other cards clean, no badges.

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/time_formatter.dart';
import '../../core/widgets/glass_card.dart';
import '../../domain/entities/prayer_time.dart';
import 'prayer_badge.dart';
import 'shimmer_text.dart';

/// حالة البطاقة / Card state
enum _CardRole { plain, current, next }

/// بطاقة صلاة مع شارات الحالة / Prayer card with status badges
class PrayerCard extends StatelessWidget {
  final PrayerTime prayerTime;
  final bool isNext;
  final bool isCurrent;
  final bool use24Hour;
  final String languageCode;

  const PrayerCard({
    super.key,
    required this.prayerTime,
    required this.isNext,
    this.isCurrent = false,
    required this.use24Hour,
    required this.languageCode,
  });

  String _prayerKey() => prayerTime.prayer.name; // fajr..isha

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    // تحديد الدور: الحالية أولاً ثم القادمة / role: current wins over next
    final _CardRole role = isCurrent
        ? _CardRole.current
        : (isNext ? _CardRole.next : _CardRole.plain);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      // خلفية بيج فاتحة هادئة للبطاقة الحالية فقط
      // calm light-beige backdrop for the current card only
      backgroundColor: role == _CardRole.current
          ? (scheme.brightness == Brightness.dark
                ? const Color(0xFFEFE7D6).withValues(alpha: 0.14)
                : const Color(0xFFEFE7D6))
          : null,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // اسم الصلاة — متلألئ للحالية فقط / name — shimmer only if current
                if (role == _CardRole.current)
                  ShimmerText(
                    l10n.tr(_prayerKey()),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    l10n.tr(_prayerKey()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 6),
                // الشارة إن وجدت / badge when applicable
                if (role == _CardRole.current)
                  PrayerBadge(label: l10n.tr('badgeCurrent'), bright: true)
                else if (role == _CardRole.next)
                  PrayerBadge(label: l10n.tr('badgeNext')),
              ],
            ),
          ),
          // الأذان / Adhan time
          Text(
            formatTime(
              prayerTime.time,
              use24Hour: use24Hour,
              languageCode: languageCode,
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: role == _CardRole.plain
                  ? FontWeight.normal
                  : FontWeight.bold,
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
                formatTime(
                  prayerTime.iqamahTime,
                  use24Hour: use24Hour,
                  languageCode: languageCode,
                ),
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
