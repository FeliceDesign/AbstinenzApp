import 'package:clean_tracker/features/milestones/domain/milestone_content.dart';
import 'package:clean_tracker/features/milestones/domain/milestone_status.dart';
import 'package:clean_tracker/core/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 1h, 1d, 1w in seconds.
  const List<int> thresholds = <int>[3600, 86400, 604800];

  group('milestoneTimeline', () {
    test('nothing reached yet — progress runs toward the first', () {
      final MilestoneTimeline t =
          milestoneTimeline(thresholds, const Duration(minutes: 30));
      expect(t.reachedCount, 0);
      expect(t.nextThresholdSeconds, 3600);
      expect(t.fractionToNext, closeTo(0.5, 1e-9)); // 30 min of 60
    });

    test('progress is measured across the current segment', () {
      // 4 days in: past 1h and 1d, heading to 1w. Segment is 1d..1w.
      final MilestoneTimeline t =
          milestoneTimeline(thresholds, const Duration(days: 4));
      expect(t.reachedCount, 2);
      expect(t.nextThresholdSeconds, 604800);
      // (4d - 1d) / (7d - 1d) = 3/6 = 0.5
      expect(t.fractionToNext, closeTo(0.5, 1e-9));
    });

    test('all reached — no next, full progress', () {
      final MilestoneTimeline t =
          milestoneTimeline(thresholds, const Duration(days: 30));
      expect(t.reachedCount, 3);
      expect(t.nextThresholdSeconds, isNull);
      expect(t.fractionToNext, 1);
    });

    test('negative duration is treated as zero', () {
      final MilestoneTimeline t =
          milestoneTimeline(thresholds, const Duration(seconds: -10));
      expect(t.reachedCount, 0);
      expect(t.fractionToNext, 0);
    });

    test('exact boundary counts as reached', () {
      expect(isReached(3600, const Duration(hours: 1)), isTrue);
      expect(isReached(3600, const Duration(minutes: 59)), isFalse);
    });
  });

  group('presetMilestones', () {
    test('nicotine seeds the time ladder plus its health set, sorted', () {
      final List<MilestoneDef> defs = presetMilestones(HabitType.nicotine);
      // Includes the 20-minute nicotine health milestone before 1h.
      expect(defs.first.key, 'nic_20m');
      expect(defs.any((MilestoneDef d) => d.key == 't_1h'), isTrue);
      // Sorted ascending by threshold.
      for (int i = 1; i < defs.length; i++) {
        expect(
          defs[i].thresholdSeconds >= defs[i - 1].thresholdSeconds,
          isTrue,
        );
      }
    });

    test('types without a health timeline still get the time ladder', () {
      final List<MilestoneDef> defs = presetMilestones(HabitType.gaming);
      expect(defs.length, timeMilestones.length);
      expect(defs.every((MilestoneDef d) => !d.isHealth), isTrue);
    });
  });
}
