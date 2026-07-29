import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../tracker/presentation/tracker_providers.dart';
import 'milestone_l10n.dart';
import 'milestone_providers.dart';

/// Invisible coordinator mounted in the app shell. It reacts to changes in the
/// habits and their active attempts (not on a timer) to:
///  - seed the preset milestones for each habit,
///  - reset achievements when a relapse restarts a streak,
///  - persist achievements for milestones already passed,
///  - (re)schedule the local notifications for future milestones.
///
/// Every side effect is guarded, so a failing database or an un-initialized
/// notification plugin (as in widget tests) never crashes the app.
class MilestoneCoordinator extends ConsumerStatefulWidget {
  const MilestoneCoordinator({super.key});

  @override
  ConsumerState<MilestoneCoordinator> createState() =>
      _MilestoneCoordinatorState();
}

class _MilestoneCoordinatorState extends ConsumerState<MilestoneCoordinator> {
  String _signature = '';
  final Map<int, DateTime?> _prevStarts = <int, DateTime?>{};
  AppLocalizations? _l10n;

  @override
  Widget build(BuildContext context) {
    _l10n = AppLocalizations.of(context);
    final List<Habit> habits =
        ref.watch(activeHabitsProvider).valueOrNull ?? const <Habit>[];

    // A signature of everything the scheduling depends on: each habit's active
    // start and its milestone rows. When it changes, re-apply after the frame.
    final StringBuffer sig = StringBuffer();
    for (final Habit h in habits) {
      final List<QuitAttempt> attempts =
          ref.watch(habitAttemptsProvider(h.id)).valueOrNull ??
              const <QuitAttempt>[];
      final QuitAttempt? active =
          attempts.where((QuitAttempt a) => a.endedAt == null).firstOrNull;
      final List<Milestone> milestones =
          ref.watch(milestonesForHabitProvider(h.id)).valueOrNull ??
              const <Milestone>[];
      sig.write('${h.id}:${active?.startedAt.microsecondsSinceEpoch}:'
          '${milestones.length};');
    }

    final String next = sig.toString();
    if (next != _signature) {
      _signature = next;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _apply();
      });
    }
    return const SizedBox.shrink();
  }

  Future<void> _apply() async {
    final List<Habit> habits =
        ref.read(activeHabitsProvider).valueOrNull ?? const <Habit>[];
    final DateTime now = ref.read(clockProvider).now();
    final NotificationService service = ref.read(notificationServiceProvider);
    final repo = ref.read(milestoneRepositoryProvider);
    final AppLocalizations? l10n = _l10n;

    final List<ScheduledMilestone> items = <ScheduledMilestone>[];
    // Cancel exactly the milestone ids (not cancelAll) so the daily mood/
    // check-in reminder — scheduled on a reserved id — survives a reschedule.
    final List<int> cancelIds = <int>[];

    for (final Habit h in habits) {
      await _guard(() => repo.ensureSeeded(h.id, h.type));

      final List<QuitAttempt> attempts =
          ref.read(habitAttemptsProvider(h.id)).valueOrNull ??
              const <QuitAttempt>[];
      final QuitAttempt? active =
          attempts.where((QuitAttempt a) => a.endedAt == null).firstOrNull;

      // Relapse detection: the active start moved → re-earn milestones.
      final DateTime? prev = _prevStarts[h.id];
      if (prev != null && active != null && prev != active.startedAt) {
        await _guard(() => repo.resetAchievements(h.id));
      }
      _prevStarts[h.id] = active?.startedAt;
      if (active == null) continue;

      final DateTime start = active.startedAt;
      final List<Milestone> milestones =
          ref.read(milestonesForHabitProvider(h.id)).valueOrNull ??
              const <Milestone>[];

      for (final Milestone m in milestones) {
        cancelIds.add(m.id);
        final DateTime reachAt =
            start.add(Duration(seconds: m.thresholdSeconds));
        if (m.achievedAt == null && !reachAt.isAfter(now)) {
          await _guard(() => repo.markAchieved(m.id, reachAt));
        }
        if (reachAt.isAfter(now) && l10n != null) {
          items.add(
            ScheduledMilestone(
              id: m.id,
              title: l10n.msNotifTitle,
              body: l10n.msNotifBody(milestoneTitle(l10n, m)),
              when: reachAt,
            ),
          );
        }
      }
    }

    await _guard(() => service.reschedule(items, cancelIds: cancelIds));
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // DB unavailable / plugin not initialized (tests) — ignore.
    }
  }
}
