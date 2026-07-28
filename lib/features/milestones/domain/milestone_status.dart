/// Pure milestone progress maths. No Flutter/drift — takes plain thresholds and
/// a clean [Duration], so it's deterministic and unit-tested.
library;

/// Reached/next/progress for a set of milestone thresholds (in seconds).
class MilestoneTimeline {
  const MilestoneTimeline({
    required this.reachedCount,
    required this.nextThresholdSeconds,
    required this.fractionToNext,
  });

  /// How many thresholds the clean time has passed.
  final int reachedCount;

  /// The next unreached threshold in seconds, or null when all are reached.
  final int? nextThresholdSeconds;

  /// Progress across the segment from the last reached milestone to the next,
  /// in `[0, 1]` (1 when everything is reached).
  final double fractionToNext;
}

/// Computes the timeline for [thresholdsSeconds] given [clean] time.
MilestoneTimeline milestoneTimeline(
  List<int> thresholdsSeconds,
  Duration clean,
) {
  final List<int> sorted = <int>[...thresholdsSeconds]..sort();
  final int cleanSecs = clean.isNegative ? 0 : clean.inSeconds;

  int reached = 0;
  for (final int t in sorted) {
    if (cleanSecs >= t) {
      reached++;
    } else {
      break;
    }
  }

  if (reached >= sorted.length) {
    return MilestoneTimeline(
      reachedCount: reached,
      nextThresholdSeconds: null,
      fractionToNext: 1,
    );
  }

  final int floor = reached == 0 ? 0 : sorted[reached - 1];
  final int next = sorted[reached];
  final double span = (next - floor).toDouble();
  final double fraction =
      span <= 0 ? 1 : ((cleanSecs - floor) / span).clamp(0.0, 1.0);

  return MilestoneTimeline(
    reachedCount: reached,
    nextThresholdSeconds: next,
    fractionToNext: fraction,
  );
}

/// Whether a threshold is reached for a given clean duration.
bool isReached(int thresholdSeconds, Duration clean) =>
    !clean.isNegative && clean.inSeconds >= thresholdSeconds;
