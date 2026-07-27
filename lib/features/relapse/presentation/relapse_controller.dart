import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../tracker/presentation/tracker_providers.dart';
import 'relapse_providers.dart';

part 'relapse_controller.g.dart';

/// Immutable form state for the relapse capture flow.
@immutable
class RelapseFormState {
  const RelapseFormState({
    required this.occurredAt,
    required this.newStartAt,
    this.trigger = '',
    this.situation = '',
    this.amount,
    this.moodBefore,
    this.note = '',
    this.wasPlanned = false,
    this.isSaving = false,
    this.saved = false,
  });

  final DateTime occurredAt;
  final DateTime newStartAt;
  final String trigger;
  final String situation;
  final double? amount;
  final int? moodBefore;
  final String note;
  final bool wasPlanned;
  final bool isSaving;
  final bool saved;

  RelapseFormState copyWith({
    DateTime? occurredAt,
    DateTime? newStartAt,
    String? trigger,
    String? situation,
    double? amount,
    bool clearAmount = false,
    int? moodBefore,
    String? note,
    bool? wasPlanned,
    bool? isSaving,
    bool? saved,
  }) {
    return RelapseFormState(
      occurredAt: occurredAt ?? this.occurredAt,
      newStartAt: newStartAt ?? this.newStartAt,
      trigger: trigger ?? this.trigger,
      situation: situation ?? this.situation,
      amount: clearAmount ? null : (amount ?? this.amount),
      moodBefore: moodBefore ?? this.moodBefore,
      note: note ?? this.note,
      wasPlanned: wasPlanned ?? this.wasPlanned,
      isSaving: isSaving ?? this.isSaving,
      saved: saved ?? this.saved,
    );
  }
}

@riverpod
class RelapseController extends _$RelapseController {
  @override
  RelapseFormState build() {
    final now = ref.read(clockProvider).now();
    return RelapseFormState(occurredAt: now, newStartAt: now);
  }

  void setOccurredAt(DateTime when) =>
      state = state.copyWith(occurredAt: when);
  void setNewStartAt(DateTime when) =>
      state = state.copyWith(newStartAt: when);
  void setTrigger(String v) => state = state.copyWith(trigger: v);
  void setSituation(String v) => state = state.copyWith(situation: v);
  void setNote(String v) => state = state.copyWith(note: v);
  void setMoodBefore(int v) => state = state.copyWith(moodBefore: v);
  void setWasPlanned(bool v) => state = state.copyWith(wasPlanned: v);

  void setAmount(String raw) {
    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    state = state.copyWith(amount: parsed, clearAmount: parsed == null);
  }

  /// Persists the relapse (close attempt, record event, open new attempt).
  Future<bool> save({required int habitId, required int quitAttemptId}) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true);
    try {
      String? nullIfBlank(String s) => s.trim().isEmpty ? null : s.trim();
      await ref.read(relapseRepositoryProvider).recordRelapse(
            habitId: habitId,
            quitAttemptId: quitAttemptId,
            occurredAt: state.occurredAt,
            newStartAt: state.newStartAt,
            trigger: nullIfBlank(state.trigger),
            situation: nullIfBlank(state.situation),
            moodBefore: state.moodBefore,
            amount: state.amount,
            note: nullIfBlank(state.note),
            wasPlanned: state.wasPlanned,
          );
      state = state.copyWith(saved: true);
      return true;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}
