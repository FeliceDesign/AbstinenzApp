import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/database.dart';
import '../../../core/theme/tokens.dart';
import '../../savings/presentation/live_now.dart';
import '../../../l10n/app_localizations.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../domain/milestone_status.dart';
import 'milestone_celebration.dart';
import 'milestone_l10n.dart';
import 'milestone_providers.dart';

/// The milestone timeline: a ring to the next milestone, then the full ladder
/// with reached / upcoming state. Reached milestones open a shareable
/// celebration. Custom milestones can be added.
class MilestonesScreen extends ConsumerStatefulWidget {
  const MilestonesScreen({super.key});

  @override
  ConsumerState<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends ConsumerState<MilestonesScreen> {
  int? _habitId;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<Habit> habits =
        ref.watch(activeHabitsProvider).valueOrNull ?? const <Habit>[];

    if (habits.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.msTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              l10n.msNoHabit,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    final Habit habit = habits.any((Habit h) => h.id == _habitId)
        ? habits.firstWhere((Habit h) => h.id == _habitId)
        : habits.first;

    final List<Milestone> milestones =
        ref.watch(milestonesForHabitProvider(habit.id)).valueOrNull ??
            const <Milestone>[];
    final List<QuitAttempt> attempts =
        ref.watch(habitAttemptsProvider(habit.id)).valueOrNull ??
            const <QuitAttempt>[];
    final QuitAttempt? active =
        attempts.where((QuitAttempt a) => a.endedAt == null).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.msTitle),
        actions: <Widget>[
          if (habits.length > 1)
            PopupMenuButton<int>(
              icon: const Icon(Icons.filter_list_rounded),
              initialValue: habit.id,
              onSelected: (int id) => setState(() => _habitId = id),
              itemBuilder: (_) => <PopupMenuEntry<int>>[
                for (final Habit h in habits)
                  PopupMenuItem<int>(value: h.id, child: Text(h.name)),
              ],
            ),
          IconButton(
            tooltip: l10n.msAdd,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _addCustom(context, habit.id),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LiveNow(
          clock: ref.watch(clockProvider),
          builder: (BuildContext context, DateTime now) {
            final Duration clean = active == null
                ? Duration.zero
                : now.difference(active.startedAt);
            final MilestoneTimeline timeline = milestoneTimeline(
              milestones.map((Milestone m) => m.thresholdSeconds).toList(),
              clean,
            );

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: <Widget>[
                _NextRing(timeline: timeline, clean: clean),
                const SizedBox(height: AppSpacing.xxl),
                for (final Milestone m in milestones)
                  _MilestoneRow(
                    milestone: m,
                    reached: isReached(m.thresholdSeconds, clean),
                    onCelebrate: () => _celebrate(context, habit, m),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _celebrate(BuildContext context, Habit habit, Milestone m) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MilestoneCelebrationScreen(
          title: milestoneTitle(l10n, m),
          subtitle: l10n.msCelebrateSub,
          habitName: habit.name,
        ),
      ),
    );
  }

  Future<void> _addCustom(BuildContext context, int habitId) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextEditingController title = TextEditingController();
    final TextEditingController days = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.msAdd),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: title,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.msAddTitleHint),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: days,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: l10n.msAddDaysHint),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final int? d = int.tryParse(days.text.trim());
    if (title.text.trim().isEmpty || d == null || d <= 0) return;
    await ref.read(milestoneRepositoryProvider).addCustom(
          habitId: habitId,
          title: title.text.trim(),
          thresholdSeconds: d * 86400,
        );
  }
}

class _NextRing extends StatelessWidget {
  const _NextRing({required this.timeline, required this.clean});
  final MilestoneTimeline timeline;
  final Duration clean;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final bool allDone = timeline.nextThresholdSeconds == null;

    return Center(
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            SizedBox(
              width: 180,
              height: 180,
              child: CircularProgressIndicator(
                value: timeline.fractionToNext,
                strokeWidth: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.brandGold,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  allDone ? l10n.msAllReached : l10n.msNext,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  allDone
                      ? '★'
                      : shortDuration(timeline.nextThresholdSeconds!),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontFeatures: AppFonts.tabular,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.milestone,
    required this.reached,
    required this.onCelebrate,
  });

  final Milestone milestone;
  final bool reached;
  final VoidCallback onCelebrate;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(
          reached
              ? Icons.check_circle_rounded
              : milestone.isCustom
                  ? Icons.star_border_rounded
                  : Icons.lock_outline_rounded,
          color: reached
              ? AppColors.brandGold
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(milestoneTitle(l10n, milestone)),
        subtitle: reached && milestone.achievedAt != null
            ? Text(
                l10n.msAchievedOn(
                  DateFormat.yMMMd(locale).format(milestone.achievedAt!),
                ),
              )
            : null,
        trailing: Text(
          shortDuration(milestone.thresholdSeconds),
          style: theme.textTheme.bodySmall,
        ),
        onTap: reached ? onCelebrate : null,
      ),
    );
  }
}
