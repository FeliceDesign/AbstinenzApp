import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/database.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/dates.dart';
import '../../../l10n/app_localizations.dart';
import '../../mood/presentation/mood_inputs.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../data/checkin_repository.dart';
import '../domain/checkin_questions.dart';
import 'checkin_l10n.dart';
import 'checkin_providers.dart';

/// The daily check-in ("Abfragen"): one short scrollable form, under a minute.
/// Back-fillable for the last 7 days; a "no" to "clean today?" gently offers the
/// relapse flow rather than forcing it.
class CheckinScreen extends ConsumerWidget {
  const CheckinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Habit>> habitsAsync = ref.watch(activeHabitsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkinTitle)),
      body: SafeArea(
        child: habitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace _) => Center(child: Text(l10n.genericError)),
          data: (List<Habit> habits) {
            if (habits.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    l10n.checkinNoHabit,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }
            return _CheckinForm(habit: habits.first);
          },
        ),
      ),
    );
  }
}

class _CheckinForm extends ConsumerStatefulWidget {
  const _CheckinForm({required this.habit});
  final Habit habit;

  @override
  ConsumerState<_CheckinForm> createState() => _CheckinFormState();
}

class _CheckinFormState extends ConsumerState<_CheckinForm> {
  late DateTime _day;
  final Map<String, dynamic> _answers = <String, dynamic>{};
  final Map<String, TextEditingController> _textControllers =
      <String, TextEditingController>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final Question q in standardCheckin) {
      if (q.type == QuestionType.freeText) {
        _textControllers[q.id] = TextEditingController();
      }
    }
    _day = dayStart(ref.read(clockProvider).now());
    _loadDay();
  }

  @override
  void dispose() {
    for (final TextEditingController c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDay() async {
    final CheckIn? existing =
        await ref.read(checkinRepositoryProvider).forDay(widget.habit.id, _day);
    if (!mounted) return;
    setState(() {
      _answers
        ..clear()
        ..addAll(existing == null ? const <String, dynamic>{} : decodeAnswers(existing.answersJson));
      for (final Question q in standardCheckin) {
        if (q.type == QuestionType.freeText) {
          final dynamic v = _answers[q.id];
          _textControllers[q.id]!.text = v is String ? v : '';
        }
      }
    });
  }

  void _pickDay(DateTime day) {
    setState(() => _day = day);
    _loadDay();
  }

  List<String> _selected(String id) {
    final dynamic v = _answers[id];
    if (v is List) return v.whereType<String>().toList();
    return <String>[];
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      // Fold free-text controllers into the answer map at save time.
      for (final MapEntry<String, TextEditingController> e
          in _textControllers.entries) {
        final String text = e.value.text.trim();
        if (text.isEmpty) {
          _answers.remove(e.key);
        } else {
          _answers[e.key] = text;
        }
      }
      await ref.read(checkinRepositoryProvider).saveForDay(
            habitId: widget.habit.id,
            day: _day,
            answers: _answers,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).checkinSaved)),
      );
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool cleanNo = _answers[QuestionIds.cleanToday] == false;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: <Widget>[
        _DaySelector(selected: _day, onSelected: _pickDay),
        const SizedBox(height: AppSpacing.lg),
        for (final Question q in standardCheckin) ...<Widget>[
          _QuestionBlock(
            question: q,
            answers: _answers,
            controller: _textControllers[q.id],
            onChanged: (dynamic v) => setState(() {
              if (v == null) {
                _answers.remove(q.id);
              } else {
                _answers[q.id] = v;
              }
            }),
            selected: _selected(q.id),
          ),
          // Gentle relapse offer right under the "clean today?" question.
          if (q.id == QuestionIds.cleanToday && cleanNo)
            _RelapseOffer(habitId: widget.habit.id),
          const SizedBox(height: AppSpacing.xl),
        ],
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.checkinSave),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.checkinBackfillHint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _QuestionBlock extends StatelessWidget {
  const _QuestionBlock({
    required this.question,
    required this.answers,
    required this.controller,
    required this.onChanged,
    required this.selected,
  });

  final Question question;
  final Map<String, dynamic> answers;
  final TextEditingController? controller;
  final ValueChanged<dynamic> onChanged;
  final List<String> selected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                checkinQuestionLabel(l10n, question.id),
                style: theme.textTheme.titleLarge,
              ),
            ),
            if (question.optional)
              Text(l10n.fieldOptional, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        switch (question.type) {
          QuestionType.yesNo => _YesNo(
              value: answers[question.id] is bool
                  ? answers[question.id] as bool
                  : null,
              onChanged: onChanged,
            ),
          QuestionType.scale => ScalePicker(
              value: answers[question.id] is int
                  ? answers[question.id] as int
                  : null,
              max: question.scaleMax,
              semanticLabel: checkinQuestionLabel(l10n, question.id),
              onChanged: onChanged,
            ),
          QuestionType.multiSelect => Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final String key in question.optionKeys)
                  FilterChip(
                    label: Text(checkinOptionLabel(l10n, key)),
                    selected: selected.contains(key),
                    onSelected: (bool on) {
                      final List<String> next = List<String>.from(selected);
                      if (on) {
                        next.add(key);
                      } else {
                        next.remove(key);
                      }
                      onChanged(next.isEmpty ? null : next);
                    },
                  ),
              ],
            ),
          QuestionType.freeText => TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(hintText: l10n.checkinFreeTextHint),
            ),
        },
      ],
    );
  }
}

class _YesNo extends StatelessWidget {
  const _YesNo({required this.value, required this.onChanged});
  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      children: <Widget>[
        ChoiceChip(
          label: Text(l10n.commonYes),
          selected: value == true,
          onSelected: (_) => onChanged(true),
        ),
        ChoiceChip(
          label: Text(l10n.commonNo),
          selected: value == false,
          onSelected: (_) => onChanged(false),
        ),
      ],
    );
  }
}

class _RelapseOffer extends StatelessWidget {
  const _RelapseOffer({required this.habitId});
  final int habitId;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.checkinRelapseOfferBody, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                OutlinedButton(
                  onPressed: () => context.push('/relapse/$habitId'),
                  child: Text(l10n.checkinRelapseOfferButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal last-7-days selector (shared shape with the mood screen).
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
