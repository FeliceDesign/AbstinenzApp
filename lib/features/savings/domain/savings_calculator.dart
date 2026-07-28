import '../../tracker/domain/streak_calculator.dart';

/// Pure savings & calorie maths. No Flutter/drift imports — this is the DoD of
/// Phase 7 and is unit-tested for versioned baselines, so it stays deterministic
/// (every function takes an explicit `now`).
///
/// The estimate is honest: money and calories "not spent / not consumed" are
/// `unitsPerDay * costPerUnit (or kcalPerUnit) * cleanDays`, integrated over the
/// clean time so that a baseline edit only affects the period from its
/// [BaselineVersion.validFrom] onward. Nothing before the first baseline counts.

/// One version of the user's baseline consumption, effective from [validFrom].
class BaselineVersion {
  const BaselineVersion({
    required this.validFrom,
    required this.unitsPerDay,
    required this.costPerUnit,
    this.kcalPerUnit,
  });

  final DateTime validFrom;
  final double unitsPerDay;
  final double costPerUnit;
  final double? kcalPerUnit;

  /// Money not spent per day at this baseline.
  double get moneyPerDay => unitsPerDay * costPerUnit;

  /// Calories not consumed per day at this baseline (0 if kcal is unset).
  double get kcalPerDay => (kcalPerUnit ?? 0) * unitsPerDay;
}

/// Accumulated savings over the clean time.
class SavingsResult {
  const SavingsResult({
    required this.money,
    required this.calories,
    required this.cleanDays,
  });

  static const SavingsResult zero =
      SavingsResult(money: 0, calories: 0, cleanDays: 0);

  /// Money not spent, in the baseline currency.
  final double money;

  /// Calories not consumed.
  final double calories;

  /// Fractional clean days that were actually covered by a baseline.
  final double cleanDays;
}

const double _secondsPerDay = 86400;

/// Integrates the baselines over the clean spans.
///
/// [cleanSpans] are the quit-attempt spans (each clean from its start to its
/// end, or to [now] when active). [baselines] may be in any order; they are
/// treated as step functions: version *i* applies from its `validFrom` until the
/// next version's `validFrom` (the latest applies to `now`). Time before the
/// earliest `validFrom` earns nothing — we won't invent an estimate for a period
/// the user never described.
SavingsResult computeSavings({
  required List<AttemptSpan> cleanSpans,
  required List<BaselineVersion> baselines,
  required DateTime now,
}) {
  if (baselines.isEmpty || cleanSpans.isEmpty) return SavingsResult.zero;

  final List<BaselineVersion> sorted = List<BaselineVersion>.of(baselines)
    ..sort(
      (BaselineVersion a, BaselineVersion b) =>
          a.validFrom.compareTo(b.validFrom),
    );

  double money = 0;
  double calories = 0;
  double days = 0;

  for (final AttemptSpan span in cleanSpans) {
    final DateTime spanStart = span.startedAt;
    final DateTime spanEnd = span.endedAt ?? now;
    if (!spanEnd.isAfter(spanStart)) continue;

    for (int i = 0; i < sorted.length; i++) {
      final DateTime segStart = sorted[i].validFrom;
      final DateTime segEnd =
          i + 1 < sorted.length ? sorted[i + 1].validFrom : now;
      if (!segEnd.isAfter(segStart)) continue;

      // Overlap of [spanStart, spanEnd] with [segStart, segEnd].
      final DateTime lo = spanStart.isAfter(segStart) ? spanStart : segStart;
      final DateTime hi = spanEnd.isBefore(segEnd) ? spanEnd : segEnd;
      if (!hi.isAfter(lo)) continue;

      final double overlapDays = hi.difference(lo).inSeconds / _secondsPerDay;
      money += sorted[i].moneyPerDay * overlapDays;
      calories += sorted[i].kcalPerDay * overlapDays;
      days += overlapDays;
    }
  }

  return SavingsResult(money: money, calories: calories, cleanDays: days);
}

/// A single habit's clean spans plus its baseline history — the inputs needed
/// to compute its share of the app-wide savings.
class HabitSaving {
  const HabitSaving({required this.cleanSpans, required this.baselines});

  final List<AttemptSpan> cleanSpans;
  final List<BaselineVersion> baselines;
}

/// Total savings across every habit (each computed with its own baselines).
SavingsResult totalSavings(List<HabitSaving> habits, DateTime now) {
  double money = 0;
  double calories = 0;
  double days = 0;
  for (final HabitSaving h in habits) {
    final SavingsResult r = computeSavings(
      cleanSpans: h.cleanSpans,
      baselines: h.baselines,
      now: now,
    );
    money += r.money;
    calories += r.calories;
    days += r.cleanDays;
  }
  return SavingsResult(money: money, calories: calories, cleanDays: days);
}

/// Summed money-per-day rate across habits (for live counting / projections).
double totalMoneyPerDay(List<HabitSaving> habits) {
  double sum = 0;
  for (final HabitSaving h in habits) {
    sum += currentMoneyPerDay(h.baselines);
  }
  return sum;
}

/// Summed calories-per-day rate across habits.
double totalKcalPerDay(List<HabitSaving> habits) {
  double sum = 0;
  for (final HabitSaving h in habits) {
    sum += currentKcalPerDay(h.baselines);
  }
  return sum;
}

/// Money-per-day of the currently effective baseline (the latest one), used for
/// live counting and projections. 0 when there is no baseline.
double currentMoneyPerDay(List<BaselineVersion> baselines) {
  if (baselines.isEmpty) return 0;
  return _latest(baselines).moneyPerDay;
}

/// Calories-per-day of the currently effective baseline.
double currentKcalPerDay(List<BaselineVersion> baselines) {
  if (baselines.isEmpty) return 0;
  return _latest(baselines).kcalPerDay;
}

BaselineVersion _latest(List<BaselineVersion> baselines) => baselines.reduce(
      (BaselineVersion a, BaselineVersion b) =>
          b.validFrom.isAfter(a.validFrom) ? b : a,
    );

/// Projected total money after [days] more days at [perDay], on top of [current].
double projectMoney(double current, double perDay, int days) =>
    current + perDay * days;

/// A savings goal's progress against the current saved amount.
class GoalProgress {
  const GoalProgress({
    required this.fraction,
    required this.remaining,
    required this.reached,
    this.daysToReach,
  });

  /// Progress in `[0, 1]`.
  final double fraction;

  /// Money still needed (0 once reached).
  final double remaining;

  /// Whether the goal is already covered by current savings.
  final bool reached;

  /// Estimated days until reached at the current rate, or null if not
  /// projectable (rate is 0) or already reached.
  final int? daysToReach;
}

GoalProgress goalProgress({
  required double target,
  required double saved,
  required double perDay,
}) {
  if (target <= 0) {
    return const GoalProgress(fraction: 1, remaining: 0, reached: true);
  }
  final double remaining = target - saved;
  if (remaining <= 0) {
    return const GoalProgress(fraction: 1, remaining: 0, reached: true);
  }
  final double fraction = (saved / target).clamp(0.0, 1.0);
  final int? daysToReach = perDay > 0 ? (remaining / perDay).ceil() : null;
  return GoalProgress(
    fraction: fraction,
    remaining: remaining,
    reached: false,
    daysToReach: daysToReach,
  );
}
