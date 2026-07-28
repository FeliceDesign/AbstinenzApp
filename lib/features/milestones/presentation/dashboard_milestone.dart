import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/database.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../savings/presentation/live_now.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../domain/milestone_status.dart';
import 'milestone_l10n.dart';
import 'milestone_providers.dart';

/// Dashboard card: the next milestone with a progress ring (spec dashboard #2).
/// Hidden until milestones exist for the first active habit.
class DashboardNextMilestone extends ConsumerWidget {
  const DashboardNextMilestone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final List<Habit> habits =
        ref.watch(activeHabitsProvider).valueOrNull ?? const <Habit>[];
    if (habits.isEmpty) return const SizedBox.shrink();
    final Habit habit = habits.first;

    final List<Milestone> milestones =
        ref.watch(milestonesForHabitProvider(habit.id)).valueOrNull ??
            const <Milestone>[];
    if (milestones.isEmpty) return const SizedBox.shrink();

    final List<QuitAttempt> attempts =
        ref.watch(habitAttemptsProvider(habit.id)).valueOrNull ??
            const <QuitAttempt>[];
    final QuitAttempt? active =
        attempts.where((QuitAttempt a) => a.endedAt == null).firstOrNull;
    if (active == null) return const SizedBox.shrink();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.push('/milestones'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: LiveNow(
            clock: ref.watch(clockProvider),
            builder: (BuildContext context, DateTime now) {
              final MilestoneTimeline t = milestoneTimeline(
                milestones.map((Milestone m) => m.thresholdSeconds).toList(),
                now.difference(active.startedAt),
              );
              final bool allDone = t.nextThresholdSeconds == null;
              return Row(
                children: <Widget>[
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        CircularProgressIndicator(
                          value: t.fractionToNext,
                          strokeWidth: 5,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.brandGold,
                          ),
                        ),
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 20,
                          color: AppColors.brandGold,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          allDone ? l10n.msAllReached : l10n.msNext,
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          allDone
                              ? l10n.msTitle
                              : shortDuration(t.nextThresholdSeconds!),
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
