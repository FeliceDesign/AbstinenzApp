import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../domain/savings_presets.dart';
import 'savings_providers.dart';

const List<String> _currencies = <String>['EUR', 'USD', 'GBP', 'CHF'];

/// Opens the baseline editor for [habit] as a modal bottom sheet.
Future<void> showBaselineEditor(BuildContext context, Habit habit) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      // Lift above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _BaselineEditor(habit: habit),
    ),
  );
}

class _BaselineEditor extends ConsumerStatefulWidget {
  const _BaselineEditor({required this.habit});
  final Habit habit;

  @override
  ConsumerState<_BaselineEditor> createState() => _BaselineEditorState();
}

class _BaselineEditorState extends ConsumerState<_BaselineEditor> {
  final TextEditingController _units = TextEditingController();
  final TextEditingController _cost = TextEditingController();
  final TextEditingController _kcal = TextEditingController();
  String _currency = 'EUR';
  bool _saving = false;

  bool get _hasCalories => habitTypeHasCalories(widget.habit.type);

  @override
  void initState() {
    super.initState();
    final List<BaselineUsage> rows =
        ref.read(baselinesForHabitProvider(widget.habit.id)).valueOrNull ??
            const <BaselineUsage>[];
    if (rows.isNotEmpty) {
      final BaselineUsage last = rows.last;
      _units.text = _fmt(last.unitsPerDay);
      _cost.text = _fmt(last.costPerUnit);
      _kcal.text = last.kcalPerUnit == null ? '' : _fmt(last.kcalPerUnit!);
      _currency = last.currency;
    } else {
      final BaselinePreset p = baselinePreset(widget.habit.type);
      _units.text = _fmt(p.unitsPerDay);
      _cost.text = _fmt(p.costPerUnit);
      _kcal.text = p.kcalPerUnit == null ? '' : _fmt(p.kcalPerUnit!);
    }
  }

  @override
  void dispose() {
    _units.dispose();
    _cost.dispose();
    _kcal.dispose();
    super.dispose();
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  double? _parse(String raw) => double.tryParse(raw.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final double? units = _parse(_units.text);
    final double? cost = _parse(_cost.text);
    if (units == null || cost == null || _saving) return;
    setState(() => _saving = true);
    try {
      // First baseline covers all clean time so far; later edits apply from now.
      final List<BaselineUsage> existing =
          ref.read(baselinesForHabitProvider(widget.habit.id)).valueOrNull ??
              const <BaselineUsage>[];
      final DateTime now = ref.read(clockProvider).now();
      DateTime validFrom = now;
      if (existing.isEmpty) {
        final List<QuitAttempt> attempts =
            ref.read(habitAttemptsProvider(widget.habit.id)).valueOrNull ??
                const <QuitAttempt>[];
        validFrom = attempts.isEmpty
            ? widget.habit.createdAt
            : attempts
                .map((QuitAttempt a) => a.startedAt)
                .reduce((DateTime a, DateTime b) => a.isBefore(b) ? a : b);
      }
      await ref.read(baselineRepositoryProvider).addVersion(
            habitId: widget.habit.id,
            unitsPerDay: units,
            costPerUnit: cost,
            currency: _currency,
            kcalPerUnit: _hasCalories ? _parse(_kcal.text) : null,
            validFrom: validFrom,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l10n.savBaselineTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.savBaselineHelp,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _units,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.savUnitsPerDay),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _cost,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        InputDecoration(labelText: l10n.savCostPerUnit),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                DropdownButton<String>(
                  value: _currency,
                  onChanged: (String? v) =>
                      setState(() => _currency = v ?? 'EUR'),
                  items: <DropdownMenuItem<String>>[
                    for (final String c in _currencies)
                      DropdownMenuItem<String>(value: c, child: Text(c)),
                  ],
                ),
              ],
            ),
            if (_hasCalories) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _kcal,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.savKcalPerUnit),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed:
                  (_parse(_units.text) != null && _parse(_cost.text) != null)
                      ? _save
                      : null,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}
