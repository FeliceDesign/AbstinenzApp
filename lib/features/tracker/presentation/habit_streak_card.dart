import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../core/db/database.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/color_field_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../relapse/domain/clean_stats.dart';
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

    return ColorFieldCard(
      gradient: AppColors.heroGradient,
      radius: AppRadius.xl,
      child: attemptsAsync.when(
        loading: () => const SizedBox(
          height: 220,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
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
          final CleanStats stats = cleanStats(spans, clock.now());

          return Column(
            children: [
              _Header(habit: habit),
              const SizedBox(height: AppSpacing.lg),
              if (startedAt != null)
                StreakTicker(
                  startedAt: startedAt,
                  clock: clock,
                  detailed: detailed,
                  onField: true,
                )
              else
                Text(
                  l10n.noActiveAttempt,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
              const SizedBox(height: AppSpacing.lg),
              _Meta(
                longestDays: longest.inDays,
                attemptNo: attemptNo,
                startedAt: startedAt,
                stats: stats,
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: FieldPill(
                  onTap: () => ref
                      .read(tickerDetailedProvider.notifier)
                      .state = !detailed,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        detailed
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(detailed ? l10n.dashDaysOnly : l10n.dashDetail),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.habit});
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Row(
      children: [
        // The habit sits in a translucent pill (mockup's "🌿 Cannabis" tag).
        Flexible(
          child: FieldPill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(habit.type.icon, size: 16),
                const SizedBox(width: AppSpacing.xs + 2),
                Flexible(
                  child: Text(
                    habit.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        // Relapse is reached via a low-key overflow menu, never a prominent
        // button next to the streak (avoids mis-taps).
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          onSelected: (value) {
            if (value == 'relapse') {
              context.push('${AppRoutes.relapse}/${habit.id}');
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'relapse', child: Text(l10n.cardMenuRelapse)),
          ],
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
    required this.stats,
  });

  final int longestDays;
  final int attemptNo;
  final DateTime? startedAt;
  final CleanStats stats;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    // On the colour field, the meta lines read as translucent white.
    final TextStyle? metaStyle = theme.textTheme.bodyMedium
        ?.copyWith(color: Colors.white.withValues(alpha: 0.75));
    final TextStyle? sinceStyle = theme.textTheme.bodySmall
        ?.copyWith(color: Colors.white.withValues(alpha: 0.6));

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            Text(l10n.dashLongestStreak(longestDays), style: metaStyle),
            Text(l10n.dashAttempt(attemptNo), style: metaStyle),
          ],
        ),
        if (startedAt != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.dashCleanSince(
              DateFormat.yMMMd(locale).add_Hm().format(startedAt!),
            ),
            style: sinceStyle,
          ),
        ],
        // History figure — only meaningful once there's been a relapse. Never
        // resets to zero; it's the sum across all attempts.
        if (attemptNo > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.cleanTotal(stats.cleanDays, stats.trackedDays, stats.percent),
            textAlign: TextAlign.center,
            style: metaStyle,
          ),
        ],
      ],
    );
  }
}
