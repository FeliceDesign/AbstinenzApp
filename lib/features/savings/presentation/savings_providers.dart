import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/prefs/preferences_provider.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../data/baseline_repository.dart';
import '../data/saving_goal_repository.dart';
import '../domain/savings_calculator.dart';
import '../domain/savings_presets.dart';

part 'savings_providers.g.dart';

@riverpod
BaselineRepository baselineRepository(BaselineRepositoryRef ref) =>
    BaselineRepository(ref.watch(databaseProvider));

@riverpod
SavingGoalRepository savingGoalRepository(SavingGoalRepositoryRef ref) =>
    SavingGoalRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
    );

@riverpod
Stream<List<BaselineUsage>> baselinesForHabit(
  BaselinesForHabitRef ref,
  int habitId,
) =>
    ref.watch(baselineRepositoryProvider).watchForHabit(habitId);

@riverpod
Stream<List<SavingGoal>> savingGoals(SavingGoalsRef ref) =>
    ref.watch(savingGoalRepositoryProvider).watchAll();

/// The clean spans + baselines of every active habit — the inputs for the
/// app-wide savings totals.
@riverpod
List<HabitSaving> savingInputs(SavingInputsRef ref) {
  final List<Habit> habits =
      ref.watch(activeHabitsProvider).valueOrNull ?? const <Habit>[];
  return <HabitSaving>[
    for (final Habit h in habits)
      HabitSaving(
        cleanSpans: toSpans(
          ref.watch(habitAttemptsProvider(h.id)).valueOrNull ??
              const <QuitAttempt>[],
        ),
        baselines: <BaselineVersion>[
          for (final BaselineUsage b
              in ref.watch(baselinesForHabitProvider(h.id)).valueOrNull ??
                  const <BaselineUsage>[])
            BaselineVersion(
              validFrom: b.validFrom,
              unitsPerDay: b.unitsPerDay,
              costPerUnit: b.costPerUnit,
              kcalPerUnit: b.kcalPerUnit,
            ),
        ],
      ),
  ];
}

/// Whether any active habit has a baseline set at all.
@riverpod
bool hasAnyBaseline(HasAnyBaselineRef ref) => ref
    .watch(savingInputsProvider)
    .any((HabitSaving h) => h.baselines.isNotEmpty);

/// Whether a calorie counter is meaningful for any active habit.
@riverpod
bool anyCalorieHabit(AnyCalorieHabitRef ref) {
  final List<Habit> habits =
      ref.watch(activeHabitsProvider).valueOrNull ?? const <Habit>[];
  return habits.any((Habit h) => habitTypeHasCalories(h.type));
}

/// Currency to display totals in — taken from the first baseline, default EUR.
/// ([BaselineVersion] intentionally drops currency, so read the raw rows.)
@riverpod
String savingsCurrency(SavingsCurrencyRef ref) {
  final List<Habit> habits =
      ref.watch(activeHabitsProvider).valueOrNull ?? const <Habit>[];
  for (final Habit h in habits) {
    final List<BaselineUsage> rows =
        ref.watch(baselinesForHabitProvider(h.id)).valueOrNull ??
            const <BaselineUsage>[];
    if (rows.isNotEmpty) return rows.first.currency;
  }
  return 'EUR';
}

/// User setting: show the calorie counter. Default on; persisted in prefs.
@riverpod
class CaloriesEnabled extends _$CaloriesEnabled {
  static const String _key = 'calories_enabled';

  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  Future<void> set({required bool value}) async {
    await ref.read(sharedPreferencesProvider).setBool(_key, value);
    state = value;
  }
}
