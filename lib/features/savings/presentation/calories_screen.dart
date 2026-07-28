import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../domain/calorie_equivalents.dart';
import '../domain/savings_calculator.dart';
import 'live_now.dart';
import 'savings_format.dart';
import 'savings_providers.dart';

/// Calorie counter: calories "not consumed", with tangible equivalents. Clearly
/// an estimate; no weight/BMI/target logic. Can be switched off here.
class CaloriesScreen extends ConsumerWidget {
  const CaloriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final List<HabitSaving> inputs = ref.watch(savingInputsProvider);
    final bool enabled = ref.watch(caloriesEnabledProvider);
    final bool hasKcal = totalKcalPerDay(inputs) > 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: <Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.calDisableToggle),
              value: enabled,
              onChanged: (bool v) => ref
                  .read(caloriesEnabledProvider.notifier)
                  .set(value: v),
            ),
            const Divider(height: AppSpacing.xxl),
            if (!enabled)
              Text(l10n.calDisabledState, style: theme.textTheme.bodyMedium)
            else if (!hasKcal)
              Text(l10n.calNoData, style: theme.textTheme.bodyMedium)
            else
              LiveNow(
                clock: ref.watch(clockProvider),
                builder: (BuildContext context, DateTime now) {
                  final double kcal = totalSavings(inputs, now).calories;
                  final List<CalorieEquivalent> equivalents =
                      calorieEquivalents(kcal);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        formatKcal(locale, kcal),
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: AppColors.brandSand,
                          fontFeatures: AppFonts.tabular,
                        ),
                      ),
                      Text(
                        l10n.calNotConsumed,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      if (equivalents.isNotEmpty) ...<Widget>[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.calEquivTitle,
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (final CalorieEquivalent e in equivalents)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                              ),
                              child: Text(
                                calorieEquivalentLabel(l10n, e),
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ),
                      ],
                    ],
                  );
                },
              ),
            const SizedBox(height: AppSpacing.xxl),
            Text(l10n.calDisabledNote, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
