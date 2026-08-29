// لوحة تشخيص جدولة الإشعارات / Notification scheduling diagnostics panel
// تعرض حالة الإشعارات المجمولة والأذونات

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/services/adhan_notification_service.dart';
import '../providers/notification_provider.dart';
import '../widgets/luxury_components.dart';

/// لوحة تشخيص الإشعارات / Notification diagnostics panel
class NotificationDiagnosticsPanel extends ConsumerStatefulWidget {
  const NotificationDiagnosticsPanel({super.key});

  @override
  ConsumerState<NotificationDiagnosticsPanel> createState() =>
      _NotificationDiagnosticsPanelState();
}

class _NotificationDiagnosticsPanelState
    extends ConsumerState<NotificationDiagnosticsPanel> {
  int? _pending;
  bool? _notifsEnabled;
  bool? _exactGranted;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _refresh();
    // تحديث عند أي تغيير إعدادات
    ref.listenManual(notificationProvider, (_, __) => _refresh());
  }

  Future<void> _refresh() async {
    final AdhanNotificationService service = AdhanNotificationService.instance;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final int pending = await service.pendingCount();
    final bool? notifs = await service.notificationsEnabled();
    final bool? exact = await service.canScheduleExact();
    if (mounted) {
      setState(() {
        _pending = pending;
        _notifsEnabled = notifs;
        _exactGranted = exact;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (_checking) {
      return const LuxuryPanel(
        child: SizedBox(
          height: 32,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    final bool allOk = (_notifsEnabled == true) && (_exactGranted == true);
    return LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                allOk ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: allOk ? Colors.green : Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  allOk
                      ? l10n.tr('notifPermissionGranted')
                      : l10n.tr('notifPermissionMissing'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: allOk ? null : Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.tr('notifScheduled')}: $_pending',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.tr('notifRefresh')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
