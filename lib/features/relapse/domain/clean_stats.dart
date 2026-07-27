import '../../tracker/domain/streak_calculator.dart';

/// Aggregate clean-time history across all attempts of a habit.
///
/// This is the "progress is never reset to zero" figure: only the current
/// streak resets on a relapse, while [cleanDays] keeps the sum of every clean
/// span. Pure and deterministic (takes an explicit `now`).
class CleanStats {
  const CleanStats({
    required this.cleanDays,
    required this.trackedDays,
    required this.ratio,
  });

  /// Whole days summed across every attempt.
  final int cleanDays;

  /// Whole days from the earliest attempt start until `now`.
  final int trackedDays;

  /// Clean fraction in `[0, 1]` (clean time / tracked time).
  final double ratio;

  /// Ratio as a rounded whole percentage.
  int get percent => (ratio * 100).round();
}

CleanStats cleanStats(List<AttemptSpan> attempts, DateTime now) {
  final Duration clean = totalCleanTime(attempts, now);

  DateTime? earliest;
  for (final AttemptSpan a in attempts) {
    if (earliest == null || a.startedAt.isBefore(earliest)) {
      earliest = a.startedAt;
    }
  }

  final Duration tracked = (earliest == null || now.isBefore(earliest))
      ? Duration.zero
      : now.difference(earliest);

  final double ratio = tracked.inSeconds == 0
      ? 0
      : (clean.inSeconds / tracked.inSeconds).clamp(0.0, 1.0);

  return CleanStats(
    cleanDays: clean.inDays,
    trackedDays: tracked.inDays,
    ratio: ratio,
  );
}
