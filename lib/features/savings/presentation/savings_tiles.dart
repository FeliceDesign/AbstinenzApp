import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../domain/savings_calculator.dart';
import 'live_now.dart';
import 'savings_format.dart';
import 'savings_providers.dart';

/// The dashboard "Saved / Calories" tile row (spec: two tiles side by side).
/// Both count live. If no baseline is set yet, a single prompt tile invites the
/// user to set one up.
class DashboardSavingsTiles extends ConsumerWidget {
  const DashboardSavingsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final List<HabitSaving> inputs = ref.watch(savingInputsProvider);
    final bool hasBaseline = ref.watch(hasAnyBaselineProvider);
    final String currency = ref.watch(savingsCurrencyProvider);
    final bool caloriesOn = ref.watch(caloriesEnabledProvider);
    final bool calorieHabit = ref.watch(anyCalorieHabitProvider);
    final bool showCalories =
        caloriesOn && calorieHabit && totalKcalPerDay(inputs) > 0;

    if (!hasBaseline) {
      return _PromptTile(onTap: () => context.push('/savings'));
    }

    return LiveNow(
      clock: ref.watch(clockProvider),
      builder: (BuildContext context, DateTime now) {
        final SavingsResult r = totalSavings(inputs, now);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: _ValueTile(
                icon: Icons.savings_rounded,
                label: l10n.savTileSaved,
                value: formatMoney(locale, currency, r.money),
                onTap: () => context.push('/savings'),
              ),
            ),
            if (showCalories) ...<Widget>[
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ValueTile(
                  icon: Icons.local_fire_department_rounded,
                  label: l10n.savTileCalories,
                  value: '${formatKcal(locale, r.calories)} kcal',
                  onTap: () => context.push('/calories'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, size: 18, color: AppColors.brandSand),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(label, style: theme.textTheme.labelMedium),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontFeatures: AppFonts.tabular,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptTile extends StatelessWidget {
  const _PromptTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: <Widget>[
              // Coloured icon-badge on a neutral card — the mockup's
              // `.card-savings`, the one card that stays neutral per screen.
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brandSkyLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: AppColors.brandSkyOnLight,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.savSetupTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.savSetupBody,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
