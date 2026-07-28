import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/database.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/dates.dart';
import '../../../l10n/app_localizations.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../data/mood_repository.dart';
import 'mood_inputs.dart';
import 'mood_l10n.dart';
import 'mood_providers.dart';

/// Daily mood entry. Supports back-filling the last 7 days (no guilt for missed
/// days — the spec's rule). Mood and energy are required; sleep, tags and note
/// are optional.
class MoodEntryScreen extends ConsumerStatefulWidget {
  const MoodEntryScreen({super.key});

  @override
  ConsumerState<MoodEntryScreen> createState() => _MoodEntryScreenState();
}

class _MoodEntryScreenState extends ConsumerState<MoodEntryScreen> {
  late DateTime _day;
  int? _score;
  int? _energy;
  int? _sleep;
  Set<String> _tags = <String>{};
  final TextEditingController _note = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _day = dayStart(ref.read(clockProvider).now());
    _loadDay();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadDay() async {
    final MoodEntry? e = await ref.read(moodRepositoryProvider).forDay(_day);
    if (!mounted) return;
    setState(() {
      _score = e?.moodScore;
      _energy = e?.energy;
      _sleep = e?.sleepQuality;
      _tags = e == null ? <String>{} : decodeTags(e.tags).toSet();
      _note.text = e?.note ?? '';
    });
  }

  void _pickDay(DateTime day) {
    setState(() => _day = day);
    _loadDay();
  }

  Future<void> _save() async {
    if (_score == null || _energy == null || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(moodRepositoryProvider).upsertForDay(
            day: _day,
            moodScore: _score!,
            energy: _energy!,
            sleepQuality: _sleep,
            tags: _tags.toList(),
            note: _note.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).moodSaved)),
      );
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final bool canSave = _score != null && _energy != null && !_saving;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.moodEntryTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: <Widget>[
            _DaySelector(selected: _day, onSelected: _pickDay),
            const SizedBox(height: AppSpacing.xl),
            _Label(text: l10n.moodScoreLabel),
            const SizedBox(height: AppSpacing.md),
            MoodFacePicker(
              value: _score,
              onChanged: (int v) => setState(() => _score = v),
            ),
            const SizedBox(height: AppSpacing.xl),
            _Label(text: l10n.moodEnergyLabel),
            const SizedBox(height: AppSpacing.md),
            ScalePicker(
              value: _energy,
              semanticLabel: l10n.moodEnergyLabel,
              onChanged: (int v) => setState(() => _energy = v),
            ),
            const SizedBox(height: AppSpacing.xl),
            _Label(text: l10n.moodSleepLabel, optional: true),
            const SizedBox(height: AppSpacing.md),
            ScalePicker(
              value: _sleep,
              semanticLabel: l10n.moodSleepLabel,
              onChanged: (int v) => setState(
                () => _sleep = _sleep == v ? null : v,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _Label(text: l10n.moodTagsLabel, optional: true),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final String key in moodTagKeys)
                  FilterChip(
                    label: Text(moodTagLabel(l10n, key)),
                    selected: _tags.contains(key),
                    onSelected: (bool on) => setState(() {
                      if (on) {
                        _tags.add(key);
                      } else {
                        _tags.remove(key);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _Label(text: l10n.moodNoteLabel, optional: true),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(hintText: l10n.moodNoteHint),
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              onPressed: canSave ? _save : null,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.moodSave),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.moodBackfillHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal selector for the last 7 days (today + 6 back). Back-fill only —
/// future days are never offered.
class _DaySelector extends ConsumerWidget {
  const _DaySelector({required this.selected, required this.onSelected});

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final DateTime today = dayStart(ref.watch(clockProvider).now());

    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          for (int back = 0; back < 7; back++)
            Builder(
              builder: (BuildContext context) {
                final DateTime day = addDays(today, -back);
                final bool isSelected = day == selected;
                return Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: ChoiceChip(
                    selected: isSelected,
                    onSelected: (_) => onSelected(day),
                    label: Text(
                      back == 0
                          ? AppLocalizations.of(context).dateToday
                          : DateFormat.MMMd(locale).format(day),
                    ),
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                    selectedColor: theme.colorScheme.primary,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, this.optional = false});
  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Text(text, style: theme.textTheme.titleLarge),
        if (optional) ...<Widget>[
          const SizedBox(width: AppSpacing.sm),
          Text(l10n.fieldOptional, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}
