import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/utils/dates.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../data/checkin_repository.dart';
import '../domain/checkin_streak.dart';

part 'checkin_providers.g.dart';

@riverpod
CheckinRepository checkinRepository(CheckinRepositoryRef ref) =>
    CheckinRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
    );

/// All check-ins across habits, oldest first.
@riverpod
Stream<List<CheckIn>> checkins(CheckinsRef ref) =>
    ref.watch(checkinRepositoryProvider).watchAll();

/// Local-midnight days that have at least one completed check-in.
@riverpod
Set<DateTime> checkinDays(CheckinDaysRef ref) {
  final List<CheckIn> rows =
      ref.watch(checkinsProvider).valueOrNull ?? const <CheckIn>[];
  return <DateTime>{
    for (final CheckIn c in rows) dayStart(c.date),
  };
}

/// Consecutive-day check-in streak (gentle: still current if only yesterday
/// is done). See [checkinStreak].
@riverpod
int checkinStreakCount(CheckinStreakCountRef ref) => checkinStreak(
      ref.watch(checkinDaysProvider),
      ref.watch(clockProvider).now(),
    );

/// Whether today already has a check-in.
@riverpod
bool checkinDoneToday(CheckinDoneTodayRef ref) {
  final DateTime today = dayStart(ref.watch(clockProvider).now());
  return ref.watch(checkinDaysProvider).contains(today);
}
