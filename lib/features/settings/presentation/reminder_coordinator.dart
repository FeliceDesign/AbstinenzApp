import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../l10n/app_localizations.dart';
import 'settings_providers.dart';

/// Invisible coordinator (mounted in the app shell) that keeps the daily
/// mood/check-in reminder in sync with its setting. It reschedules whenever the
/// on/off flag or the time changes, and re-applies on every app launch (so the
/// wall-clock anchor self-corrects across daylight-saving changes).
///
/// Guarded throughout: an un-initialized notification plugin (as in widget
/// tests) never crashes the app.
class ReminderCoordinator extends ConsumerStatefulWidget {
  const ReminderCoordinator({super.key});

  @override
  ConsumerState<ReminderCoordinator> createState() =>
      _ReminderCoordinatorState();
}

class _ReminderCoordinatorState extends ConsumerState<ReminderCoordinator> {
  String _signature = '';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ReminderConfig cfg = ref.watch(dailyReminderSettingProvider);

    final String next = '${cfg.enabled}:${cfg.hour}:${cfg.minute}';
    if (next != _signature) {
      _signature = next;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _apply(cfg, l10n);
      });
    }
    return const SizedBox.shrink();
  }

  Future<void> _apply(ReminderConfig cfg, AppLocalizations l10n) async {
    final NotificationService service = ref.read(notificationServiceProvider);
    try {
      if (cfg.enabled) {
        await service.scheduleDailyReminder(
          hour: cfg.hour,
          minute: cfg.minute,
          title: l10n.reminderTitle,
          body: l10n.reminderBody,
        );
      } else {
        await service.cancelDailyReminder();
      }
    } catch (_) {
      // Plugin not initialized (tests) — ignore.
    }
  }
}
