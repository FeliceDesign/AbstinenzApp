import '../../../core/db/database.dart';

/// Per-habit-type baseline suggestions and whether a calorie counter is
/// meaningful for the type. Values are rough starting points the user edits;
/// they only pre-fill the baseline form.
class BaselinePreset {
  const BaselinePreset({
    required this.unitsPerDay,
    required this.costPerUnit,
    this.kcalPerUnit,
  });

  final double unitsPerDay;
  final double costPerUnit;
  final double? kcalPerUnit;
}

/// Whether "calories not consumed" makes sense for [type]. Only caloric habits
/// qualify; for the rest the calorie counter is hidden entirely.
bool habitTypeHasCalories(HabitType type) =>
    type == HabitType.alcohol || type == HabitType.sugar;

/// A starting baseline for [type]. Costs are in the default currency (EUR);
/// kcal is null where calories don't apply.
BaselinePreset baselinePreset(HabitType type) => switch (type) {
      // ~one 0.5 l beer: 210 kcal, ~2.50 €.
      HabitType.alcohol =>
        const BaselinePreset(unitsPerDay: 2, costPerUnit: 2.5, kcalPerUnit: 210),
      // a cigarette from a ~7 €/20 pack.
      HabitType.nicotine =>
        const BaselinePreset(unitsPerDay: 15, costPerUnit: 0.35),
      HabitType.cannabis =>
        const BaselinePreset(unitsPerDay: 0.5, costPerUnit: 10),
      // a sugary portion ~150 kcal.
      HabitType.sugar =>
        const BaselinePreset(unitsPerDay: 2, costPerUnit: 1.5, kcalPerUnit: 150),
      HabitType.gaming =>
        const BaselinePreset(unitsPerDay: 2, costPerUnit: 0),
      HabitType.porn => const BaselinePreset(unitsPerDay: 1, costPerUnit: 0),
      HabitType.other => const BaselinePreset(unitsPerDay: 1, costPerUnit: 0),
    };
