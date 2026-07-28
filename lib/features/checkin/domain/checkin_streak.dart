import '../../../core/utils/dates.dart';

/// Consecutive-day check-in streak ("X Check-ins in Folge").
///
/// Pure and DST-safe (steps days via the calendar, not a 24 h [Duration]).
/// Gentle by design: the streak is still considered current if today has no
/// check-in yet but yesterday did, so opening the app in the morning does not
/// show the streak as already broken. Returns 0 when the most recent check-in
/// is older than yesterday.
///
/// [days] is the set of local-midnight days that have a completed check-in;
/// [today] is the current day (any time — it is normalised here).
int checkinStreak(Set<DateTime> days, DateTime today) {
  final Set<DateTime> normalized = <DateTime>{
    for (final DateTime d in days) dayStart(d),
  };
  if (normalized.isEmpty) return 0;

  DateTime cursor = dayStart(today);
  // Grace: if today isn't done yet, anchor the count on yesterday.
  if (!normalized.contains(cursor)) {
    cursor = addDays(cursor, -1);
    if (!normalized.contains(cursor)) return 0;
  }

  int streak = 0;
  while (normalized.contains(cursor)) {
    streak++;
    cursor = addDays(cursor, -1);
  }
  return streak;
}
