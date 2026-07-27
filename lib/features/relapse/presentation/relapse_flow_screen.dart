import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../tracker/presentation/tracker_providers.dart';
import 'relapse_controller.dart';

/// Relapse capture flow.
///
/// Deliberately colourless: only neutrals + secondary text, no signal colour,
/// no red, no warning icon. A relapse is a data point, not an alarm. Reached
/// from the habit card's overflow menu (never a big button next to the streak,
/// to avoid mis-taps).
class RelapseFlowScreen extends ConsumerStatefulWidget {
  const RelapseFlowScreen({required this.habitId, super.key});

  final int habitId;

  @override
  ConsumerState<RelapseFlowScreen> createState() => _RelapseFlowScreenState();
}

class _RelapseFlowScreenState extends ConsumerState<RelapseFlowScreen> {
  int _step = 0; // 0 = pause, 1 = capture, 2 = done

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final attemptsAsync = ref.watch(habitAttemptsProvider(widget.habitId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.relTitle)),
      body: SafeArea(
        child: attemptsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.genericError)),
          data: (attempts) {
            final active = attempts.where((a) => a.endedAt == null).toList();
            if (active.isEmpty) {
              return Center(child: Text(l10n.noActiveAttempt));
            }
            final int attemptId = active.first.id;
            return switch (_step) {
              0 => _PauseStep(
                  onProceed: () => setState(() => _step = 1),
                  onCancel: () => context.pop(),
                ),
              1 => _CaptureStep(
                  habitId: widget.habitId,
                  quitAttemptId: attemptId,
                  onSaved: () => setState(() => _step = 2),
                ),
              _ => _DoneStep(onFinish: () => context.pop()),
            };
          },
        ),
      ),
    );
  }
}

/// Neutral filled button — the flow avoids the primary (cool) brand colour.
class _NeutralButton extends StatelessWidget {
  const _NeutralButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

class _PauseStep extends StatefulWidget {
  const _PauseStep({required this.onProceed, required this.onCancel});
  final VoidCallback onProceed;
  final VoidCallback onCancel;

  @override
  State<_PauseStep> createState() => _PauseStepState();
}

class _PauseStepState extends State<_PauseStep> {
  static const Duration _wait = Duration(minutes: 15);
  Timer? _timer;
  Duration _remaining = _wait;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startWait() {
    setState(() {
      _running = true;
      _remaining = _wait;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (_remaining <= Duration.zero) {
          _remaining = Duration.zero;
          _running = false;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String mmss =
        '${_remaining.inMinutes.toString().padLeft(2, '0')}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(l10n.relPauseTitle, style: theme.textTheme.headlineLarge),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.relPauseBody, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.xl),
        // 15-minute "not never, just not now" timer (optional).
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.relWaitHint, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                if (_running)
                  Text(
                    l10n.relWaitRemaining(mmss),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontFeatures: AppFonts.tabular,
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _startWait,
                    icon: const Icon(Icons.timer_outlined, size: 18),
                    label: Text(l10n.relWait15),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _NeutralButton(label: l10n.relProceed, onPressed: widget.onProceed),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: widget.onCancel,
          child: Text(l10n.relCancel),
        ),
      ],
    );
  }
}

class _CaptureStep extends ConsumerWidget {
  const _CaptureStep({
    required this.habitId,
    required this.quitAttemptId,
    required this.onSaved,
  });

  final int habitId;
  final int quitAttemptId;
  final VoidCallback onSaved;

  Future<void> _pickDateTime(
    BuildContext context,
    WidgetRef ref, {
    required DateTime current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final DateTime now = ref.read(clockProvider).now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: current.isAfter(now) ? now : current,
      firstDate: DateTime(now.year - 20),
      lastDate: now,
    );
    if (date == null || !context.mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (!context.mounted) return;
    final DateTime picked = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? current.hour,
      time?.minute ?? current.minute,
    );
    onPicked(picked.isAfter(now) ? now : picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final state = ref.watch(relapseControllerProvider);
    final controller = ref.read(relapseControllerProvider.notifier);
    final String locale = Localizations.localeOf(context).toString();
    final DateFormat fmt = DateFormat.yMMMEd(locale).add_Hm();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(l10n.relCaptureTitle, style: theme.textTheme.headlineLarge),
        const SizedBox(height: AppSpacing.xl),
        _FieldTile(
          label: l10n.relOccurredAt,
          value: fmt.format(state.occurredAt),
          icon: Icons.schedule_rounded,
          onTap: () => _pickDateTime(
            context,
            ref,
            current: state.occurredAt,
            onPicked: controller.setOccurredAt,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          decoration: _dec(l10n.relTrigger),
          onChanged: controller.setTrigger,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          decoration: _dec(l10n.relSituation),
          onChanged: controller.setSituation,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _dec(l10n.relAmount),
          onChanged: controller.setAmount,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.relMood, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        _MoodRow(
          selected: state.moodBefore,
          onSelected: controller.setMoodBefore,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          minLines: 2,
          maxLines: 4,
          decoration: _dec(l10n.relNote),
          onChanged: controller.setNote,
        ),
        const SizedBox(height: AppSpacing.lg),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: state.wasPlanned,
          onChanged: controller.setWasPlanned,
          title: Text(l10n.relPlanned),
        ),
        const Divider(height: AppSpacing.xxl),
        _FieldTile(
          label: l10n.relNewStart,
          value: fmt.format(state.newStartAt),
          icon: Icons.restart_alt_rounded,
          onTap: () => _pickDateTime(
            context,
            ref,
            current: state.newStartAt,
            onPicked: controller.setNewStartAt,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () =>
                controller.setNewStartAt(ref.read(clockProvider).now()),
            icon: const Icon(Icons.bolt_rounded, size: 18),
            label: Text(l10n.relNewStartNow),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _NeutralButton(
          label: l10n.relSave,
          busy: state.isSaving,
          onPressed: () async {
            final ok = await controller.save(
              habitId: habitId,
              quitAttemptId: quitAttemptId,
            );
            if (ok) onSaved();
          },
        ),
      ],
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      );
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label, style: theme.textTheme.bodySmall),
        subtitle: Text(value, style: theme.textTheme.bodyLarge),
        trailing: const Icon(Icons.edit_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }
}

/// Neutral 1–5 selector (no mood colours here — the relapse flow stays grey).
class _MoodRow extends StatelessWidget {
  const _MoodRow({required this.selected, required this.onSelected});
  final int? selected;
  final ValueChanged<int> onSelected;

  static const List<IconData> _faces = [
    Icons.sentiment_very_dissatisfied_rounded,
    Icons.sentiment_dissatisfied_rounded,
    Icons.sentiment_neutral_rounded,
    Icons.sentiment_satisfied_rounded,
    Icons.sentiment_very_satisfied_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < 5; i++)
          IconButton(
            iconSize: 32,
            onPressed: () => onSelected(i + 1),
            isSelected: selected == i + 1,
            icon: Icon(
              _faces[i],
              color: selected == i + 1
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.onFinish});
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.spa_outlined,
            size: 44,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.relDoneTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.relDoneBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxl),
          _NeutralButton(label: l10n.relDoneButton, onPressed: onFinish),
        ],
      ),
    );
  }
}
