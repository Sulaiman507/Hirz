// لوحة إعدادات إشعارات الصلوات / Prayer notification settings panel
// تُعرض في شاشة الإعدادات لكل صلاة / shown in settings screen for each prayer

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/entities/prayer_time.dart';
import '../providers/notification_provider.dart';

/// صف إعدادات صلاة واحدة / Single prayer notification row
class PrayerNotificationTile extends ConsumerWidget {
  final Prayer prayer;
  final String label;

  const PrayerNotificationTile({
    super.key,
    required this.prayer,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<NotificationSettings> async = ref.watch(
      notificationProvider,
    );

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (NotificationSettings settings) {
        final PrayerNotification? pn = settings.prayers[prayer];
        final bool enabled = pn?.enabled ?? false;
        final AlertType type = pn?.type ?? AlertType.shortTone;

        return Column(
          children: <Widget>[
            SwitchListTile(
              title: Text(label),
              value: enabled,
              onChanged: (bool v) => ref
                  .read(notificationProvider.notifier)
                  .togglePrayer(prayer, v),
            ),
            if (enabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: SegmentedButton<AlertType>(
                        segments: <ButtonSegment<AlertType>>[
                          ButtonSegment<AlertType>(
                            value: AlertType.fullAdhan,
                            label: Text(l10n.tr('notifAlertFull')),
                          ),
                          ButtonSegment<AlertType>(
                            value: AlertType.shortTone,
                            label: Text(l10n.tr('notifAlertShort')),
                          ),
                          ButtonSegment<AlertType>(
                            value: AlertType.silent,
                            label: Text(l10n.tr('notifAlertSilent')),
                          ),
                        ],
                        selected: <AlertType>{type},
                        onSelectionChanged: (Set<AlertType> sel) => ref
                            .read(notificationProvider.notifier)
                            .setAlertType(prayer, sel.first),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
