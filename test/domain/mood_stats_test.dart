import 'package:clean_tracker/features/mood/domain/mood_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MoodDay mood(int d, int score) =>
      MoodDay(day: DateTime(2026, 1, d), moodScore: score, energy: 3);

  group('averageScore', () {
    test('is null for an empty iterable', () {
      expect(averageScore(const <int>[]), isNull);
    });
    test('averages values', () {
      expect(averageScore(<int>[1, 2, 3]), 2.0);
      expect(averageScore(<int>[4, 5]), 4.5);
    });
  });

  group('moodSeries', () {
    test('keeps only entries inside the window, sorted ascending', () {
      final List<MoodDay> entries = <MoodDay>[
        mood(12, 5),
        mood(8, 2),
        mood(3, 1), // before window
        mood(10, 4),
      ];
      final List<MoodPoint> s =
          moodSeries(entries, DateTime(2026, 1, 8), DateTime(2026, 1, 12));
      expect(s.map((MoodPoint p) => p.day.day), <int>[8, 10, 12]);
      expect(s.map((MoodPoint p) => p.score), <int>[2, 4, 5]);
    });

    test('window bounds are inclusive by calendar day', () {
      final List<MoodDay> entries = <MoodDay>[mood(8, 3), mood(12, 3)];
      final s =
          moodSeries(entries, DateTime(2026, 1, 8, 20), DateTime(2026, 1, 12, 6));
      expect(s.length, 2);
    });
  });

  group('compareMoodByUrge', () {
    test('splits mood by whether the day had an urge', () {
      final List<MoodDay> entries = <MoodDay>[
        mood(1, 2),
        mood(2, 4),
        mood(3, 5),
      ];
      final Set<DateTime> urgeDays = <DateTime>{DateTime(2026, 1, 1)};
      final MoodUrgeComparison c = compareMoodByUrge(entries, urgeDays);
      expect(c.avgWithUrge, 2.0);
      expect(c.daysWithUrge, 1);
      expect(c.avgWithoutUrge, 4.5);
      expect(c.daysWithoutUrge, 2);
      expect(c.hasData, isTrue);
    });

    test('hasData is false when one side is empty', () {
      final c = compareMoodByUrge(<MoodDay>[mood(1, 3)], <DateTime>{});
      expect(c.hasData, isFalse);
    });
  });

  group('moodAroundRelapse', () {
    test('averages mood at each offset around relapse days', () {
      final List<MoodDay> entries = <MoodDay>[
        mood(9, 4), // day before relapse (offset -1)
        mood(10, 2), // relapse day (offset 0)
        mood(11, 3), // day after (offset +1)
      ];
      final Set<DateTime> relapseDays = <DateTime>{DateTime(2026, 1, 10)};
      final List<MoodOffset> offsets =
          moodAroundRelapse(entries, relapseDays);

      expect(offsets.length, 7); // -3..+3
      MoodOffset at(int o) =>
          offsets.firstWhere((MoodOffset x) => x.offset == o);
      expect(at(-1).average, 4.0);
      expect(at(0).average, 2.0);
      expect(at(1).average, 3.0);
      expect(at(-3).average, isNull);
      expect(at(-3).count, 0);
    });
  });
}
