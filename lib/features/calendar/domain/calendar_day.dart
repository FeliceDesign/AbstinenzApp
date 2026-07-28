import '../../../core/utils/dates.dart';
import '../../tracker/domain/streak_calculator.dart';

/// Pure calendar-model logic. No Flutter/drift imports so it is unit-testable.
///
/// A month is rendered as a heatmap; every cell encodes several facts at once,
/// which this file computes as plain data (the widget maps them to colours):
///  - [status]: clean / relapse / none (before tracking or a gap),
///  - [cleanRun]: how many consecutive clean days end on this one — drives the
///    "the month warms up" opacity ramp,
///  - [moodScore]: 1..5 if a mood was logged (a small dot),
///  - [checkinDone]: whether the daily check-in was completed (a ring).

enum DayStatus { clean, relapse, none }

class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.status,
    required this.cleanRun,
    required this.inFuture,
    this.moodScore,
    this.checkinDone = false,
  });

  /// Local midnight of the day.
  final DateTime date;
  final DayStatus status;

  /// Consecutive clean days ending on this day (0 unless [status] is clean).
  final int cleanRun;

  /// True for days after "now" — shown muted and non-interactive.
  final bool inFuture;

  final int? moodScore;
  final bool checkinDone;
}

/// Builds the [CalendarDay] list for one month (day 1..last), in order.
///
/// [attempts] are the quit-attempt spans of the habit the calendar is showing;
/// [relapseDays] the local-midnight days that habit relapsed; [moodByDay] and
/// [checkinDays] are app-wide. A day is:
///  - **relapse** if it is in [relapseDays];
///  - **clean** if it lies within an attempt span (from its start day up to the
///    relapse day exclusive, or up to today for the active attempt);
///  - **none** otherwise (before the first attempt, or the future).
List<CalendarDay> buildCalendarMonth({
  required int year,
  required int month,
  required List<AttemptSpan> attempts,
  required Set<DateTime> relapseDays,
  required Map<DateTime, int> moodByDay,
  required Set<DateTime> checkinDays,
  required DateTime now,
}) {
  final DateTime today = dayStart(now);
  final int count = daysInMonth(year, month);

  final List<CalendarDay> days = <CalendarDay>[];
  for (int d = 1; d <= count; d++) {
    final DateTime day = DateTime(year, month, d);
    final bool inFuture = day.isAfter(today);

    DayStatus status;
    int cleanRun = 0;
    if (relapseDays.contains(day)) {
      status = DayStatus.relapse;
    } else if (!inFuture && _coveringStart(day, attempts, today) != null) {
      status = DayStatus.clean;
      cleanRun = daysBetween(_coveringStart(day, attempts, today)!, day) + 1;
    } else {
      status = DayStatus.none;
    }

    days.add(
      CalendarDay(
        date: day,
        status: status,
        cleanRun: cleanRun,
        inFuture: inFuture,
        moodScore: moodByDay[day],
        checkinDone: checkinDays.contains(day),
      ),
    );
  }
  return days;
}

/// The start day of the attempt covering [day], or null if none covers it.
/// A day is covered from the attempt's start day up to (but excluding) its end
/// day; the active attempt runs up to and including [today].
DateTime? _coveringStart(DateTime day, List<AttemptSpan> attempts, DateTime today) {
  for (final AttemptSpan a in attempts) {
    final DateTime start = dayStart(a.startedAt);
    if (day.isBefore(start)) continue;
    final DateTime? end = a.endedAt == null ? null : dayStart(a.endedAt!);
    // Active attempt: clean through today. Closed attempt: clean until the day
    // before the relapse day (the relapse day itself renders as a relapse).
    final bool covered =
        end == null ? !day.isAfter(today) : day.isBefore(end);
    if (covered) return start;
  }
  return null;
}

/// Opacity tier (0..3) for a clean day's warmth, from its running streak length.
/// 1–2 days → 0, 3–6 → 1, 7–29 → 2, 30+ → 3. The widget maps these to the
/// 25/45/70/100 % gold opacities in the design spec.
int warmthTier(int cleanRun) {
  if (cleanRun >= 30) return 3;
  if (cleanRun >= 7) return 2;
  if (cleanRun >= 3) return 1;
  return 0;
}
