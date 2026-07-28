import '../../../core/utils/dates.dart';

/// Pure mood analysis. No Flutter/drift imports so it is trivially unit-tested.
///
/// Everything here is honest and descriptive: the correlation helpers report
/// *observations* (averages, counts), never a diagnosis. The presentation layer
/// is responsible for the non-clinical wording; this file only does the maths.

/// A single day's mood, projected from a persisted entry.
class MoodDay {
  const MoodDay({
    required this.day,
    required this.moodScore,
    required this.energy,
    this.sleepQuality,
  });

  /// Local midnight of the entry's calendar day.
  final DateTime day;

  /// Mood on the 1..5 ordinal scale.
  final int moodScore;

  /// Energy on the 1..5 scale.
  final int energy;

  /// Sleep quality 1..5, optional.
  final int? sleepQuality;
}

/// A point on the mood line chart.
class MoodPoint {
  const MoodPoint({required this.day, required this.score});

  final DateTime day;
  final int score;
}

/// Mood points inside the window `[from, to]` (inclusive, by calendar day),
/// sorted ascending. Days without an entry are simply absent — the chart draws
/// a continuous line across gaps rather than inventing zeros.
List<MoodPoint> moodSeries(
  List<MoodDay> entries,
  DateTime from,
  DateTime to,
) {
  final DateTime lo = dayStart(from);
  final DateTime hi = dayStart(to);
  final List<MoodPoint> points = <MoodPoint>[
    for (final MoodDay e in entries)
      if (!e.day.isBefore(lo) && !e.day.isAfter(hi))
        MoodPoint(day: e.day, score: e.moodScore),
  ]..sort((MoodPoint a, MoodPoint b) => a.day.compareTo(b.day));
  return points;
}

/// Mean of [scores], or null for an empty list.
double? averageScore(Iterable<int> scores) {
  int sum = 0;
  int n = 0;
  for (final int s in scores) {
    sum += s;
    n++;
  }
  return n == 0 ? null : sum / n;
}

/// Average mood on days that had an urge versus days that did not.
///
/// [urgeDays] is the set of local-midnight days on which at least one urge was
/// logged. Only days that also have a mood entry are counted on either side.
class MoodUrgeComparison {
  const MoodUrgeComparison({
    required this.avgWithUrge,
    required this.daysWithUrge,
    required this.avgWithoutUrge,
    required this.daysWithoutUrge,
  });

  final double? avgWithUrge;
  final int daysWithUrge;
  final double? avgWithoutUrge;
  final int daysWithoutUrge;

  /// Both sides need at least one day for the comparison to mean anything.
  bool get hasData => daysWithUrge > 0 && daysWithoutUrge > 0;
}

MoodUrgeComparison compareMoodByUrge(
  List<MoodDay> moods,
  Set<DateTime> urgeDays,
) {
  final List<int> withUrge = <int>[];
  final List<int> withoutUrge = <int>[];
  for (final MoodDay m in moods) {
    if (urgeDays.contains(m.day)) {
      withUrge.add(m.moodScore);
    } else {
      withoutUrge.add(m.moodScore);
    }
  }
  return MoodUrgeComparison(
    avgWithUrge: averageScore(withUrge),
    daysWithUrge: withUrge.length,
    avgWithoutUrge: averageScore(withoutUrge),
    daysWithoutUrge: withoutUrge.length,
  );
}

/// Average mood at a day-offset relative to relapse days.
class MoodOffset {
  const MoodOffset({
    required this.offset,
    required this.average,
    required this.count,
  });

  /// Days relative to a relapse day (e.g. -1 = the day before, +2 = two after).
  final int offset;

  /// Mean mood across all matching (relapseDay + offset) days, or null if none.
  final double? average;

  /// How many mood entries contributed.
  final int count;
}

/// Mood in a `±window`-day band around relapse days.
///
/// For each offset in `[-window, +window]`, averages the mood of every day that
/// sits that many days from *some* relapse day. Reported as a shape, not a
/// cause — the UI frames it as "what your mood looked like around these days".
List<MoodOffset> moodAroundRelapse(
  List<MoodDay> moods,
  Set<DateTime> relapseDays, {
  int window = 3,
}) {
  final Map<DateTime, int> moodByDay = <DateTime, int>{
    for (final MoodDay m in moods) m.day: m.moodScore,
  };

  final List<MoodOffset> result = <MoodOffset>[];
  for (int offset = -window; offset <= window; offset++) {
    final List<int> scores = <int>[];
    for (final DateTime r in relapseDays) {
      final int? s = moodByDay[addDays(r, offset)];
      if (s != null) scores.add(s);
    }
    result.add(
      MoodOffset(
        offset: offset,
        average: averageScore(scores),
        count: scores.length,
      ),
    );
  }
  return result;
}
