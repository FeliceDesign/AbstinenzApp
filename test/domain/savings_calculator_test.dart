import 'package:clean_tracker/features/savings/domain/savings_calculator.dart';
import 'package:clean_tracker/features/tracker/domain/streak_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime(2026, 1, 11);

  group('computeSavings', () {
    test('no baselines or no spans yields zero', () {
      expect(
        computeSavings(cleanSpans: const [], baselines: const [], now: now),
        SavingsResult.zero,
      );
      expect(
        computeSavings(
          cleanSpans: <AttemptSpan>[
            AttemptSpan(startedAt: DateTime(2026, 1, 1)),
          ],
          baselines: const [],
          now: now,
        ).money,
        0,
      );
    });

    test('single baseline over an active span', () {
      final SavingsResult r = computeSavings(
        cleanSpans: <AttemptSpan>[AttemptSpan(startedAt: DateTime(2026, 1, 1))],
        baselines: <BaselineVersion>[
          BaselineVersion(
            validFrom: DateTime(2026, 1, 1),
            unitsPerDay: 2,
            costPerUnit: 2.5,
            kcalPerUnit: 210,
          ),
        ],
        now: now,
      );
      expect(r.cleanDays, 10);
      expect(r.money, 10 * 5); // 2 * 2.50 * 10 days
      expect(r.calories, 10 * 420); // 2 * 210 * 10 days
    });

    test('a baseline edit only applies from its validFrom (DoD)', () {
      final SavingsResult r = computeSavings(
        cleanSpans: <AttemptSpan>[AttemptSpan(startedAt: DateTime(2026, 1, 1))],
        baselines: <BaselineVersion>[
          // 5 €/day for the first 5 days …
          BaselineVersion(
            validFrom: DateTime(2026, 1, 1),
            unitsPerDay: 2,
            costPerUnit: 2.5,
          ),
          // … then 10 €/day from the 6th on.
          BaselineVersion(
            validFrom: DateTime(2026, 1, 6),
            unitsPerDay: 4,
            costPerUnit: 2.5,
          ),
        ],
        now: now,
      );
      // Jan 1–6 = 5 days @ 5 = 25; Jan 6–11 = 5 days @ 10 = 50.
      expect(r.money, 25 + 50);
      expect(r.cleanDays, 10);
    });

    test('time before the first baseline earns nothing', () {
      final SavingsResult r = computeSavings(
        cleanSpans: <AttemptSpan>[AttemptSpan(startedAt: DateTime(2026, 1, 1))],
        baselines: <BaselineVersion>[
          BaselineVersion(
            validFrom: DateTime(2026, 1, 6),
            unitsPerDay: 2,
            costPerUnit: 2.5,
          ),
        ],
        now: now,
      );
      expect(r.cleanDays, 5); // only Jan 6–11
      expect(r.money, 25);
    });

    test('sums closed and active spans, skipping the relapse gap', () {
      final SavingsResult r = computeSavings(
        cleanSpans: <AttemptSpan>[
          AttemptSpan(
            startedAt: DateTime(2026, 1, 1),
            endedAt: DateTime(2026, 1, 5),
          ),
          AttemptSpan(startedAt: DateTime(2026, 1, 8)),
        ],
        baselines: <BaselineVersion>[
          BaselineVersion(
            validFrom: DateTime(2026, 1, 1),
            unitsPerDay: 1,
            costPerUnit: 10,
          ),
        ],
        now: now,
      );
      // 4 clean days + 3 clean days = 7, at 10 €/day = 70.
      expect(r.cleanDays, 7);
      expect(r.money, 70);
    });
  });

  group('goalProgress', () {
    test('projects days to reach at the current rate', () {
      final GoalProgress g =
          goalProgress(target: 100, saved: 40, perDay: 10);
      expect(g.reached, isFalse);
      expect(g.remaining, 60);
      expect(g.fraction, closeTo(0.4, 1e-9));
      expect(g.daysToReach, 6);
    });

    test('already reached when saved covers target', () {
      final GoalProgress g =
          goalProgress(target: 100, saved: 120, perDay: 10);
      expect(g.reached, isTrue);
      expect(g.remaining, 0);
      expect(g.fraction, 1);
    });

    test('no projection when the rate is zero', () {
      final GoalProgress g = goalProgress(target: 100, saved: 0, perDay: 0);
      expect(g.daysToReach, isNull);
    });
  });
}
