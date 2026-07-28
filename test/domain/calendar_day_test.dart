import 'package:clean_tracker/features/calendar/domain/calendar_day.dart';
import 'package:clean_tracker/features/tracker/domain/streak_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CalendarDay dayOf(List<CalendarDay> days, int d) =>
      days.firstWhere((CalendarDay c) => c.date.day == d);

  group('buildCalendarMonth', () {
    test('active attempt marks clean days with a growing run', () {
      final days = buildCalendarMonth(
        year: 2026,
        month: 1,
        attempts: <AttemptSpan>[
          AttemptSpan(startedAt: DateTime(2026, 1, 7, 12)),
        ],
        relapseDays: <DateTime>{},
        moodByDay: <DateTime, int>{DateTime(2026, 1, 8): 4},
        checkinDays: <DateTime>{DateTime(2026, 1, 9)},
        now: DateTime(2026, 1, 10, 12),
      );

      expect(days.length, 31);
      expect(dayOf(days, 6).status, DayStatus.none); // before start
      expect(dayOf(days, 7).status, DayStatus.clean);
      expect(dayOf(days, 7).cleanRun, 1);
      expect(dayOf(days, 8).cleanRun, 2);
      expect(dayOf(days, 8).moodScore, 4);
      expect(dayOf(days, 9).checkinDone, isTrue);
      expect(dayOf(days, 10).cleanRun, 4);
      // The future stays blank and flagged.
      expect(dayOf(days, 11).status, DayStatus.none);
      expect(dayOf(days, 11).inFuture, isTrue);
    });

    test('relapse day renders as relapse; prior days of that attempt are clean',
        () {
      final days = buildCalendarMonth(
        year: 2026,
        month: 1,
        attempts: <AttemptSpan>[
          AttemptSpan(
            startedAt: DateTime(2026, 1, 1),
            endedAt: DateTime(2026, 1, 5, 9),
          ),
          AttemptSpan(startedAt: DateTime(2026, 1, 5, 9)),
        ],
        relapseDays: <DateTime>{DateTime(2026, 1, 5)},
        moodByDay: const <DateTime, int>{},
        checkinDays: const <DateTime>{},
        now: DateTime(2026, 1, 10, 12),
      );

      expect(dayOf(days, 4).status, DayStatus.clean);
      expect(dayOf(days, 5).status, DayStatus.relapse);
      expect(dayOf(days, 6).status, DayStatus.clean);
    });
  });

  group('warmthTier', () {
    test('ramps by streak length', () {
      expect(warmthTier(1), 0);
      expect(warmthTier(2), 0);
      expect(warmthTier(3), 1);
      expect(warmthTier(6), 1);
      expect(warmthTier(7), 2);
      expect(warmthTier(29), 2);
      expect(warmthTier(30), 3);
      expect(warmthTier(400), 3);
    });
  });
}
