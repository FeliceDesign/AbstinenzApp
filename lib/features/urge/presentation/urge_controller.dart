import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/urge_technique.dart';
import 'urge_providers.dart';

part 'urge_controller.g.dart';

@immutable
class UrgeFlowState {
  const UrgeFlowState({
    this.urgeId,
    this.intensityStart = 5,
    this.intensityEnd = 5,
    this.technique,
    this.isSaving = false,
  });

  final int? urgeId;
  final int intensityStart;
  final int intensityEnd;
  final UrgeTechnique? technique;
  final bool isSaving;

  UrgeFlowState copyWith({
    int? urgeId,
    int? intensityStart,
    int? intensityEnd,
    UrgeTechnique? technique,
    bool? isSaving,
  }) {
    return UrgeFlowState(
      urgeId: urgeId ?? this.urgeId,
      intensityStart: intensityStart ?? this.intensityStart,
      intensityEnd: intensityEnd ?? this.intensityEnd,
      technique: technique ?? this.technique,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

@riverpod
class UrgeController extends _$UrgeController {
  @override
  UrgeFlowState build() => const UrgeFlowState();

  void setIntensityStart(int v) => state = state.copyWith(intensityStart: v);
  void setIntensityEnd(int v) => state = state.copyWith(intensityEnd: v);
  void selectTechnique(UrgeTechnique t) => state = state.copyWith(technique: t);

  /// Creates the urge event as soon as the initial intensity is captured.
  Future<void> start() async {
    if (state.urgeId != null) return; // already started
    final int id = await ref
        .read(urgeRepositoryProvider)
        .startUrge(intensityStart: state.intensityStart);
    state = state.copyWith(urgeId: id);
  }

  /// Writes the after-measurement and the technique used.
  Future<void> complete() async {
    final int? id = state.urgeId;
    final UrgeTechnique? t = state.technique;
    if (id == null || t == null || state.isSaving) return;
    state = state.copyWith(isSaving: true);
    try {
      await ref.read(urgeRepositoryProvider).completeUrge(
            id: id,
            intensityEnd: state.intensityEnd,
            techniqueUsed: t.name,
          );
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}
