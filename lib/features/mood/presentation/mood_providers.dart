import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/utils/dates.dart';
import '../../relapse/presentation/relapse_providers.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../../urge/presentation/urge_providers.dart';
import '../data/mood_repository.dart';
import '../domain/mood_stats.dart';

part 'mood_providers.g.dart';

@riverpod
MoodRepository moodRepository(MoodRepositoryRef ref) =>
    MoodRepository(ref.watch(databaseProvider));

/// All persisted mood entries, oldest first.
@riverpod
Stream<List<MoodEntry>> moodEntries(MoodEntriesRef ref) =>
    ref.watch(moodRepositoryProvider).watchAll();

/// The mood entry for a specific day (reactive, for the entry screen).
@riverpod
Stream<MoodEntry?> moodForDay(MoodForDayRef ref, DateTime day) =>
    ref.watch(moodRepositoryProvider).watchForDay(day);

/// Domain projection of the persisted entries.
@riverpod
List<MoodDay> moodDays(MoodDaysRef ref) {
  final List<MoodEntry> rows =
      ref.watch(moodEntriesProvider).valueOrNull ?? const <MoodEntry>[];
  return rows
      .map(
        (MoodEntry e) => MoodDay(
          day: dayStart(e.date),
          moodScore: e.moodScore,
          energy: e.energy,
          sleepQuality: e.sleepQuality,
        ),
      )
      .toList(growable: false);
}

/// Whether today already has a mood entry.
@riverpod
bool moodLoggedToday(MoodLoggedTodayRef ref) {
  final DateTime today = dayStart(ref.watch(clockProvider).now());
  final List<MoodDay> days = ref.watch(moodDaysProvider);
  return days.any((MoodDay d) => d.day == today);
}

/// Local-midnight days on which at least one urge was logged.
@riverpod
Set<DateTime> urgeDays(UrgeDaysRef ref) {
  final List<UrgeEvent> events =
      ref.watch(urgeEventsProvider).valueOrNull ?? const <UrgeEvent>[];
  return <DateTime>{
    for (final UrgeEvent e in events) dayStart(e.startedAt),
  };
}

/// Local-midnight days on which a relapse occurred.
@riverpod
Set<DateTime> relapseDays(RelapseDaysRef ref) {
  final List<RelapseEvent> events =
      ref.watch(allRelapsesProvider).valueOrNull ?? const <RelapseEvent>[];
  return <DateTime>{
    for (final RelapseEvent e in events) dayStart(e.occurredAt),
  };
}

/// Average-mood-on-urge-days vs. other days.
@riverpod
MoodUrgeComparison moodUrgeComparison(MoodUrgeComparisonRef ref) =>
    compareMoodByUrge(
      ref.watch(moodDaysProvider),
      ref.watch(urgeDaysProvider),
    );

/// Mood shape in a ±3-day band around relapse days.
@riverpod
List<MoodOffset> moodAroundRelapseDays(MoodAroundRelapseDaysRef ref) =>
    moodAroundRelapse(
      ref.watch(moodDaysProvider),
      ref.watch(relapseDaysProvider),
    );
