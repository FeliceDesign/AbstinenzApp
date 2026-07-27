/// Pure streak / clean-time calculations. No Flutter import, no `DateTime.now()`
/// — every function takes an explicit `now` so tests are deterministic across
/// time zones and DST changes.
///
/// A "quit attempt" is a span from [startedAt] until it either ends (relapse)
/// or is still running. The current streak is the running attempt's duration.
library;

/// A closed or open period of abstinence.
class AttemptSpan {
  const AttemptSpan({required this.startedAt, this.endedAt});

  /// When abstinence began.
  final DateTime startedAt;

  /// When it ended (a relapse). `null` means the attempt is still active.
  final DateTime? endedAt;

  bool get isActive => endedAt == null;
}

/// Duration of the currently active attempt, measured to [now].
///
/// Returns [Duration.zero] if [startedAt] is in the future (guards against a
/// user picking a start time ahead of "now") or if there is no active attempt.
Duration currentStreak(List<AttemptSpan> attempts, DateTime now) {
  for (final AttemptSpan a in attempts) {
    if (a.isActive) {
      if (now.isBefore(a.startedAt)) return Duration.zero;
      return now.difference(a.startedAt);
    }
  }
  return Duration.zero;
}

/// The longest attempt duration ever recorded, including the active one.
Duration longestStreak(List<AttemptSpan> attempts, DateTime now) {
  Duration best = Duration.zero;
  for (final AttemptSpan a in attempts) {
    final DateTime end = a.endedAt ?? now;
    if (end.isBefore(a.startedAt)) continue;
    final Duration d = end.difference(a.startedAt);
    if (d > best) best = d;
  }
  return best;
}

/// Total clean time accumulated across every attempt (active included).
///
/// This is the number that "never goes back to zero" — only the current streak
/// resets on a relapse, the total keeps growing.
Duration totalCleanTime(List<AttemptSpan> attempts, DateTime now) {
  Duration total = Duration.zero;
  for (final AttemptSpan a in attempts) {
    final DateTime end = a.endedAt ?? now;
    if (end.isBefore(a.startedAt)) continue;
    total += end.difference(a.startedAt);
  }
  return total;
}

/// Whole clean days accumulated across all attempts.
int totalCleanDays(List<AttemptSpan> attempts, DateTime now) =>
    totalCleanTime(attempts, now).inDays;

/// Number of attempts (the "current attempt #N" counter).
int attemptCount(List<AttemptSpan> attempts) => attempts.length;

/// Broken-down components of a duration for the live ticker display.
class StreakParts {
  const StreakParts({
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  final int days;
  final int hours;
  final int minutes;
  final int seconds;

  static StreakParts of(Duration d) {
    final Duration nonNeg = d.isNegative ? Duration.zero : d;
    return StreakParts(
      days: nonNeg.inDays,
      hours: nonNeg.inHours % 24,
      minutes: nonNeg.inMinutes % 60,
      seconds: nonNeg.inSeconds % 60,
    );
  }
}
