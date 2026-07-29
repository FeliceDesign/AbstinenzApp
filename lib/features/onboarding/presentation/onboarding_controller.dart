import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
import '../../motivation/presentation/motivation_providers.dart';
import '../../savings/presentation/savings_providers.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../domain/onboarding_gate.dart';

part 'onboarding_controller.g.dart';

/// Immutable form state for the onboarding flow.
///
/// Hand-written (rather than freezed) because it is a small, throwaway UI state
/// object; freezed is reserved for domain models that need value equality and
/// exhaustive unions in later phases.
@immutable
class OnboardingFormState {
  const OnboardingFormState({
    required this.startedAt,
    this.type,
    this.name = '',
    this.unitLabel = '',
    this.whys = const <String>[],
    this.benefits = const <String>[],
    this.consequences = const <String>[],
    this.savingsText = '',
    this.isSaving = false,
  });

  final HabitType? type;
  final String name;
  final String unitLabel;
  final DateTime startedAt;

  /// Motivations the user adds during onboarding, so the app is never empty on
  /// first open. Whys are pinned on save.
  final List<String> whys;
  final List<String> benefits;
  final List<String> consequences;

  /// Raw text of the "spend per day" field; parsed to a baseline on save.
  final String savingsText;

  final bool isSaving;

  bool get canSubmit =>
      type != null && name.trim().isNotEmpty && !isSaving;

  OnboardingFormState copyWith({
    HabitType? type,
    String? name,
    String? unitLabel,
    DateTime? startedAt,
    List<String>? whys,
    List<String>? benefits,
    List<String>? consequences,
    String? savingsText,
    bool? isSaving,
  }) {
    return OnboardingFormState(
      type: type ?? this.type,
      name: name ?? this.name,
      unitLabel: unitLabel ?? this.unitLabel,
      startedAt: startedAt ?? this.startedAt,
      whys: whys ?? this.whys,
      benefits: benefits ?? this.benefits,
      consequences: consequences ?? this.consequences,
      savingsText: savingsText ?? this.savingsText,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingFormState build() {
    // Default start time is "now"; the user can move it into the past.
    return OnboardingFormState(startedAt: ref.read(clockProvider).now());
  }

  void setType(HabitType type) => state = state.copyWith(type: type);
  void setName(String name) => state = state.copyWith(name: name);
  void setUnitLabel(String unit) => state = state.copyWith(unitLabel: unit);
  void setStartedAt(DateTime when) => state = state.copyWith(startedAt: when);
  void setSavingsText(String text) => state = state.copyWith(savingsText: text);

  void addWhy(String value) => _addTo(_Field.why, value);
  void addBenefit(String value) => _addTo(_Field.benefit, value);
  void addConsequence(String value) => _addTo(_Field.consequence, value);
  void removeWhy(int i) => _removeAt(_Field.why, i);
  void removeBenefit(int i) => _removeAt(_Field.benefit, i);
  void removeConsequence(int i) => _removeAt(_Field.consequence, i);

  void _addTo(_Field field, String value) {
    final String v = value.trim();
    if (v.isEmpty) return;
    switch (field) {
      case _Field.why:
        state = state.copyWith(whys: <String>[...state.whys, v]);
      case _Field.benefit:
        state = state.copyWith(benefits: <String>[...state.benefits, v]);
      case _Field.consequence:
        state =
            state.copyWith(consequences: <String>[...state.consequences, v]);
    }
  }

  void _removeAt(_Field field, int i) {
    List<String> without(List<String> list) =>
        <String>[for (int j = 0; j < list.length; j++) if (j != i) list[j]];
    switch (field) {
      case _Field.why:
        state = state.copyWith(whys: without(state.whys));
      case _Field.benefit:
        state = state.copyWith(benefits: without(state.benefits));
      case _Field.consequence:
        state = state.copyWith(consequences: without(state.consequences));
    }
  }

  /// Persists the habit + first quit attempt, the motivations and an optional
  /// savings baseline gathered during onboarding, then marks onboarding
  /// complete. Returns true on success. Guards against double submits.
  Future<bool> finish() async {
    if (!state.canSubmit) return false;
    state = state.copyWith(isSaving: true);
    try {
      final int habitId =
          await ref.read(habitRepositoryProvider).createHabitWithAttempt(
                name: state.name.trim(),
                type: state.type!,
                unitLabel: state.unitLabel.trim(),
                startedAt: state.startedAt,
              );

      final motivations = ref.read(motivationRepositoryProvider);
      for (final String w in state.whys) {
        await motivations.add(
          kind: MotivationKind.why,
          content: w,
          isPinned: true,
          habitId: habitId,
        );
      }
      for (final String b in state.benefits) {
        await motivations.add(
          kind: MotivationKind.benefit,
          content: b,
          habitId: habitId,
        );
      }
      for (final String c in state.consequences) {
        await motivations.add(
          kind: MotivationKind.consequence,
          content: c,
          habitId: habitId,
        );
      }

      final double? spend = _parseSpend(state.savingsText);
      if (spend != null && spend > 0) {
        await ref.read(baselineRepositoryProvider).addVersion(
              habitId: habitId,
              unitsPerDay: 1,
              costPerUnit: spend,
              currency: 'EUR',
              validFrom: state.startedAt,
            );
      }

      await ref.read(onboardingGateProvider).markComplete();
      return true;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  static double? _parseSpend(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));
}

enum _Field { why, benefit, consequence }
