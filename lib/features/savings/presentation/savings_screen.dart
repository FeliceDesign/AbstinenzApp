import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../domain/savings_calculator.dart';
import 'baseline_editor.dart';
import 'live_now.dart';
import 'savings_format.dart';
import 'savings_providers.dart';

/// Savings detail: live total, projection, per-habit baseline editing, and
/// savings goals. Everything is labelled as an estimate.
class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final List<Habit> habits =
        ref.watch(activeHabitsProvider).valueOrNull ?? const <Habit>[];
    final List<HabitSaving> inputs = ref.watch(savingInputsProvider);
    final String currency = ref.watch(savingsCurrencyProvider);
    final DateTime now = ref.watch(clockProvider).now();
    final double perDay = totalMoneyPerDay(inputs);
    final double base = totalSavings(inputs, now).money;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.savTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.savFormulaTitle,
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(l10n.savFormulaTitle),
                content: Text(l10n.savFormulaBody),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.commonClose),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: habits.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  l10n.savNoHabit,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          : SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: <Widget>[
                  _Hero(inputs: inputs, currency: currency),
                  const SizedBox(height: AppSpacing.xxl),
                  _Projection(
                    base: base,
                    perDay: perDay,
                    currency: currency,
                    locale: locale,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    l10n.savBaselinesTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final Habit h in habits) _BaselineRow(habit: h),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    l10n.savGoalsTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Goals(saved: base, perDay: perDay, currency: currency),
                ],
              ),
            ),
    );
  }
}

class _Hero extends ConsumerWidget {
  const _Hero({required this.inputs, required this.currency});
  final List<HabitSaving> inputs;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    return Column(
      children: <Widget>[
        LiveNow(
          clock: ref.watch(clockProvider),
          builder: (BuildContext context, DateTime now) {
            final double money = totalSavings(inputs, now).money;
            return ShaderMask(
              shaderCallback: (Rect bounds) => const LinearGradient(
                colors: <Color>[AppColors.brandGold, AppColors.brandSand],
              ).createShader(bounds),
              child: Text(
                formatMoney(locale, currency, money),
                style: theme.textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontFeatures: AppFonts.tabular,
                ),
              ),
            );
          },
        ),
        Text(l10n.savEstimate, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _Projection extends StatelessWidget {
  const _Projection({
    required this.base,
    required this.perDay,
    required this.currency,
    required this.locale,
  });

  final double base;
  final double perDay;
  final String currency;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    Widget row(String label, int days) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(label, style: theme.textTheme.bodyLarge),
              Text(
                formatMoney(locale, currency, projectMoney(base, perDay, days)),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFeatures: AppFonts.tabular,
                ),
              ),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.savProjectionTitle, style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            row(l10n.savProjMonth, 30),
            row(l10n.savProjYear, 365),
            row(l10n.savProj5Year, 1825),
          ],
        ),
      ),
    );
  }
}

class _BaselineRow extends ConsumerWidget {
  const _BaselineRow({required this.habit});
  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final List<BaselineUsage> rows =
        ref.watch(baselinesForHabitProvider(habit.id)).valueOrNull ??
            const <BaselineUsage>[];
    final BaselineUsage? latest = rows.isEmpty ? null : rows.last;

    final String subtitle = latest == null
        ? l10n.savBaselineNone
        : '${_num(latest.unitsPerDay)} × '
            '${formatMoney(locale, latest.currency, latest.costPerUnit)} '
            '· ${l10n.savPerDay}';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(habit.name),
        subtitle: Text(subtitle),
        trailing: TextButton(
          onPressed: () => showBaselineEditor(context, habit),
          child: Text(latest == null ? l10n.savSetBaseline : l10n.savEditBaseline),
        ),
      ),
    );
  }

  static String _num(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}

class _Goals extends ConsumerWidget {
  const _Goals({
    required this.saved,
    required this.perDay,
    required this.currency,
  });

  final double saved;
  final double perDay;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final List<SavingGoal> goals =
        ref.watch(savingGoalsProvider).valueOrNull ?? const <SavingGoal>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (goals.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(l10n.savGoalEmpty, style: theme.textTheme.bodyMedium),
          ),
        for (final SavingGoal g in goals)
          _GoalCard(
            goal: g,
            progress: goalProgress(
              target: g.targetAmount,
              saved: saved,
              perDay: perDay,
            ),
            onDelete: () =>
                ref.read(savingGoalRepositoryProvider).delete(g.id),
          ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _addGoal(context, ref, currency),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.savGoalAdd),
        ),
      ],
    );
  }

  Future<void> _addGoal(
    BuildContext context,
    WidgetRef ref,
    String currency,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextEditingController title = TextEditingController();
    final TextEditingController amount = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.savGoalAdd),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: title,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.savGoalTitleHint),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(hintText: l10n.savGoalAmountHint),
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
    final double? target =
        double.tryParse(amount.text.trim().replaceAll(',', '.'));
    if (title.text.trim().isEmpty || target == null || target <= 0) return;
    await ref.read(savingGoalRepositoryProvider).add(
          title: title.text.trim(),
          targetAmount: target,
          currency: currency,
        );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.progress,
    required this.onDelete,
  });

  final SavingGoal goal;
  final GoalProgress progress;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();

    final String status = progress.reached
        ? l10n.savGoalReached
        : progress.daysToReach != null
            ? l10n.savGoalEta(progress.daysToReach!)
            : l10n.savGoalRemaining(
                formatMoney(locale, goal.currency, progress.remaining),
              );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(goal.title, style: theme.textTheme.titleLarge),
                ),
                Text(
                  formatMoney(locale, goal.currency, goal.targetAmount),
                  style: theme.textTheme.bodyMedium,
                ),
                IconButton(
                  tooltip: l10n.commonDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress.fraction,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.brandSand),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                if (progress.reached)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.brandGold,
                  ),
                if (progress.reached) const SizedBox(width: AppSpacing.xs),
                Text(status, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
