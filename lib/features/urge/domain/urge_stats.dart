/// Pure analysis of urge outcomes. No Flutter/drift imports so it is trivially
/// unit-testable.
///
/// The core reward loop is "you rode out a wave, that was #N", so the headline
/// number is [wavesRidden]. The honest, personal insight is which technique
/// reduces intensity most for *this* user — [effectivenessByTechnique].
library;

/// Minimal projection of an urge event needed for stats.
class UrgeOutcome {
  const UrgeOutcome({
    required this.intensityStart,
    this.intensityEnd,
    this.technique,
  });

  final int intensityStart;
  final int? intensityEnd;
  final String? technique;

  /// A completed wave has an after-measurement.
  bool get isComplete => intensityEnd != null;

  /// Positive = intensity dropped (good). Null if not completed.
  int? get reduction =>
      intensityEnd == null ? null : intensityStart - intensityEnd!;
}

/// Number of completed waves (the "#N" reward counter).
int wavesRidden(List<UrgeOutcome> outcomes) =>
    outcomes.where((o) => o.isComplete).length;

/// Average intensity reduction per technique, best first. Only completed
/// outcomes with a named technique count.
class TechniqueEffectiveness {
  const TechniqueEffectiveness({
    required this.technique,
    required this.uses,
    required this.averageReduction,
  });

  final String technique;
  final int uses;
  final double averageReduction;
}

List<TechniqueEffectiveness> effectivenessByTechnique(
  List<UrgeOutcome> outcomes,
) {
  final Map<String, List<int>> byTech = {};
  for (final o in outcomes) {
    final int? r = o.reduction;
    final String? t = o.technique;
    if (r == null || t == null) continue;
    byTech.putIfAbsent(t, () => <int>[]).add(r);
  }

  final List<TechniqueEffectiveness> result = byTech.entries.map((e) {
    final double avg = e.value.reduce((a, b) => a + b) / e.value.length;
    return TechniqueEffectiveness(
      technique: e.key,
      uses: e.value.length,
      averageReduction: avg,
    );
  }).toList();

  result.sort((a, b) => b.averageReduction.compareTo(a.averageReduction));
  return result;
}
