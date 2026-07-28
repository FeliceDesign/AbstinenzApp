import 'package:clean_tracker/features/urge/domain/urge_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wavesRidden counts only completed urges', () {
    final outcomes = [
      const UrgeOutcome(intensityStart: 8, intensityEnd: 3, technique: 'a'),
      const UrgeOutcome(intensityStart: 6, intensityEnd: 2, technique: 'b'),
      const UrgeOutcome(intensityStart: 7), // abandoned, not counted
    ];
    expect(wavesRidden(outcomes), 2);
  });

  test('effectiveness ranks techniques by average reduction, best first', () {
    final outcomes = [
      const UrgeOutcome(intensityStart: 8, intensityEnd: 6, technique: 'weak'),
      const UrgeOutcome(intensityStart: 8, intensityEnd: 4, technique: 'weak'),
      const UrgeOutcome(intensityStart: 9, intensityEnd: 2, technique: 'strong'),
      const UrgeOutcome(intensityStart: 7), // no technique -> ignored
    ];

    final ranked = effectivenessByTechnique(outcomes);

    expect(ranked, hasLength(2));
    expect(ranked.first.technique, 'strong');
    expect(ranked.first.averageReduction, 7);
    expect(ranked.last.technique, 'weak');
    expect(ranked.last.uses, 2);
    expect(ranked.last.averageReduction, 3); // (2 + 4) / 2
  });

  test('empty input yields no rankings and zero waves', () {
    expect(wavesRidden(const []), 0);
    expect(effectivenessByTechnique(const []), isEmpty);
  });
}
