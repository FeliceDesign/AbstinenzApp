import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
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
    this.isSaving = false,
  });

  final HabitType? type;
  final String name;
  final String unitLabel;
  final DateTime startedAt;
  final bool isSaving;

  bool get canSubmit =>
      type != null && name.trim().isNotEmpty && !isSaving;

  OnboardingFormState copyWith({
    HabitType? type,
    String? name,
    String? unitLabel,
    DateTime? startedAt,
    bool? isSaving,
  }) {
    return OnboardingFormState(
      type: type ?? this.type,
      name: name ?? this.name,
      unitLabel: unitLabel ?? this.unitLabel,
      startedAt: startedAt ?? this.startedAt,
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

  /// Persists the habit + first quit attempt and marks onboarding complete.
  /// Returns true on success. Guards against double submits via [isSaving].
  Future<bool> finish() async {
    if (!state.canSubmit) return false;
    state = state.copyWith(isSaving: true);
    try {
      await ref.read(habitRepositoryProvider).createHabitWithAttempt(
            name: state.name.trim(),
            type: state.type!,
            unitLabel: state.unitLabel.trim(),
            startedAt: state.startedAt,
          );
      await ref.read(onboardingGateProvider).markComplete();
      return true;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}
