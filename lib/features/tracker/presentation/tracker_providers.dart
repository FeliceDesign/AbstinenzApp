import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/utils/clock.dart';
import '../data/habit_repository.dart';
import '../domain/streak_calculator.dart';

part 'tracker_providers.g.dart';

/// The app-wide clock. Overridden with a [FakeClock] in tests.
@riverpod
Clock clock(ClockRef ref) => const SystemClock();

@riverpod
HabitRepository habitRepository(HabitRepositoryRef ref) => HabitRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
    );

/// Active habits shown on the dashboard.
@riverpod
Stream<List<Habit>> activeHabits(ActiveHabitsRef ref) =>
    ref.watch(habitRepositoryProvider).watchActiveHabits();

/// Quit attempts for a single habit.
@riverpod
Stream<List<QuitAttempt>> habitAttempts(HabitAttemptsRef ref, int habitId) =>
    ref.watch(habitRepositoryProvider).watchAttempts(habitId);

/// Maps persisted [QuitAttempt] rows to the pure-domain [AttemptSpan] type used
/// by the streak calculations.
List<AttemptSpan> toSpans(List<QuitAttempt> attempts) => attempts
    .map((a) => AttemptSpan(startedAt: a.startedAt, endedAt: a.endedAt))
    .toList(growable: false);
