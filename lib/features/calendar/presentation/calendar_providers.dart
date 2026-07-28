import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
import '../../../core/utils/dates.dart';
import '../../checkin/presentation/checkin_providers.dart';
import '../../mood/presentation/mood_providers.dart';
import '../../relapse/presentation/relapse_providers.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../domain/calendar_day.dart';

part 'calendar_providers.g.dart';

/// The heatmap model for one habit and month. Composes the per-habit clean /
/// relapse history with the app-wide mood and check-in days. Recomputes
/// reactively as any of those change.
@riverpod
List<CalendarDay> calendarMonth(
  CalendarMonthRef ref,
  int habitId,
  int year,
  int month,
) {
  final List<QuitAttempt> attempts =
      ref.watch(habitAttemptsProvider(habitId)).valueOrNull ??
          const <QuitAttempt>[];
  final List<RelapseEvent> relapses =
      ref.watch(habitRelapsesProvider(habitId)).valueOrNull ??
          const <RelapseEvent>[];

  return buildCalendarMonth(
    year: year,
    month: month,
    attempts: toSpans(attempts),
    relapseDays: <DateTime>{
      for (final RelapseEvent r in relapses) dayStart(r.occurredAt),
    },
    moodByDay: <DateTime, int>{
      for (final m in ref.watch(moodDaysProvider)) m.day: m.moodScore,
    },
    checkinDays: ref.watch(checkinDaysProvider),
    now: ref.watch(clockProvider).now(),
  );
}

/// The check-in for a habit on a specific day (for the day-detail sheet).
@riverpod
Future<CheckIn?> checkinForDay(
  CheckinForDayRef ref,
  int habitId,
  DateTime day,
) =>
    ref.watch(checkinRepositoryProvider).forDay(habitId, day);
