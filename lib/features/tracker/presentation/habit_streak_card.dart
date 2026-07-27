import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/database.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/habit_type_x.dart';
import '../domain/streak_calculator.dart';
import 'streak_ticker.dart';
import 'tracker_providers.dart';

/// Whether the ticker shows the full `HH:MM:SS` detail or just the day count.
/// UI-only state, so a plain [StateProvider] rather than a generated one.
final tickerDetailedProvider = StateProvider<bool>((ref) => true);

/// A single habit's live streak, longest streak and current attempt number.
class HabitStreakCard extends ConsumerWidget {
  const HabitStreakCard({required this.habit, super.key});

  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final bool detailed = ref.watch(tickerDetailedProvider);
    final clock = ref.watch(clockProvider);
    final attemptsAsync = ref.watch(habitAttemptsProvider(habit.id));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: attemptsAsync.when(
          loading: () => const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SizedBox(
            height: 220,
            child: Center(child: Text(l10n.genericError)),
          ),
          data: (attempts) {
            final spans = toSpans(attempts);
            final active = attempts.where((a) => a.endedAt == null).toList();
            final DateTime? startedAt =
                active.isNotEmpty ? active.first.startedAt : null;
            final Duration longest = longestStreak(spans, clock.now());
            final int attemptNo = attemptCount(spans);

            return Column(
              children: [
                _Header(habit: habit),
                const SizedBox(height: AppSpacing.lg),
                if (startedAt != null)
                  StreakTicker(
                    startedAt: startedAt,
                    clock: clock,
                    detailed: detailed,
                  )
                else
                  Text(l10n.noActiveAttempt, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
                _Meta(
                  longestDays: longest.inDays,
                  attemptNo: attemptNo,
                  startedAt: startedAt,
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => ref
                        .read(tickerDetailedProvider.notifier)
                        .state = !detailed,
                    icon: Icon(
                      detailed
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                    ),
                    label: Text(
                      detailed ? l10n.dashDaysOnly : l10n.dashDetail,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.habit});
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: [
        Icon(habit.type.icon, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            habit.name,
            style: theme.textTheme.titleLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.longestDays,
    required this.attemptNo,
    required this.startedAt,
  });

  final int longestDays;
  final int attemptNo;
  final DateTime? startedAt;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            Text(
              l10n.dashLongestStreak(longestDays),
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              l10n.dashAttempt(attemptNo),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        if (startedAt != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.dashCleanSince(
              DateFormat.yMMMd(locale).add_Hm().format(startedAt!),
            ),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
