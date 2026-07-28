/// Turns "calories not consumed" into a few tangible, clearly-rough equivalents.
///
/// Pure and honest: the divisors are round approximations (documented below),
/// and the UI labels every figure as an estimate. No weight/BMI/target logic and
/// no deficit framing — this is only "here's what that adds up to".
library;

/// A single equivalent, e.g. `EquivalentKind.pizza` × 14.
enum EquivalentKind { pizza, running, chocolate }

class CalorieEquivalent {
  const CalorieEquivalent({required this.kind, required this.amount});

  final EquivalentKind kind;

  /// How many of [kind] the calories correspond to (rounded for display).
  final int amount;
}

// Rough, widely-cited round numbers (per item / per km).
const double _kcalPerPizza = 850;
const double _kcalPerKmRun = 60;
const double _kcalPerChocolateBar = 230;

/// Equivalents worth showing for [calories]. Only kinds with a count of at least
/// one are returned, so tiny totals don't show "≈ 0 pizzas".
List<CalorieEquivalent> calorieEquivalents(double calories) {
  if (calories <= 0) return const <CalorieEquivalent>[];
  final List<CalorieEquivalent> out = <CalorieEquivalent>[
    CalorieEquivalent(
      kind: EquivalentKind.pizza,
      amount: (calories / _kcalPerPizza).round(),
    ),
    CalorieEquivalent(
      kind: EquivalentKind.running,
      amount: (calories / _kcalPerKmRun).round(),
    ),
    CalorieEquivalent(
      kind: EquivalentKind.chocolate,
      amount: (calories / _kcalPerChocolateBar).round(),
    ),
  ];
  return out.where((CalorieEquivalent e) => e.amount >= 1).toList();
}
