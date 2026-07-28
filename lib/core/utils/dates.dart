/// Calendar-day helpers used by mood / check-in / calendar logic.
///
/// A "day" is the user's local calendar day. These are deliberately DST-safe:
/// stepping days reconstructs local midnight via the [DateTime] constructor
/// (`DateTime(y, m, d + n)` normalises overflow) instead of adding a fixed 24 h
/// [Duration], which would drift by an hour across a daylight-saving change.
///
/// Pure Dart, no Flutter import — safe to use from `domain/`.
library;

/// Local midnight of the day containing [t].
DateTime dayStart(DateTime t) => DateTime(t.year, t.month, t.day);

/// The day [n] calendar days after [day] (negative steps back). Operates on the
/// day component only, so the result is always a local midnight.
DateTime addDays(DateTime day, int n) =>
    DateTime(day.year, day.month, day.day + n);

/// Whether [a] and [b] fall on the same local calendar day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// A whole-day index for a date, independent of time zone / DST.
///
/// Built from the date components via a UTC instant, so it counts calendar days
/// rather than 24 h blocks — the same trick `pickDaily` uses. Handy for whole-day
/// arithmetic where a `Duration`-based diff could be off by the DST hour.
int dayNumber(DateTime day) =>
    DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;

/// Whole calendar days from [a] to [b] (negative if [b] precedes [a]).
int daysBetween(DateTime a, DateTime b) => dayNumber(b) - dayNumber(a);

/// Number of days in [month] of [year] (handles leap years).
int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// First day (local midnight) of [month] in [year].
DateTime monthStart(int year, int month) => DateTime(year, month, 1);

/// [start] shifted by [delta] whole months (the constructor normalises
/// overflow, so month 13 becomes January of the next year).
DateTime addMonths(DateTime start, int delta) =>
    DateTime(start.year, start.month + delta, 1);

/// Whole months between two month-starts (`b` minus `a`).
int monthsBetween(DateTime a, DateTime b) =>
    (b.year - a.year) * 12 + (b.month - a.month);
