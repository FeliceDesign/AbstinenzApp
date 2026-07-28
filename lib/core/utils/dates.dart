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
