import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/database.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/dates.dart';
import '../../../l10n/app_localizations.dart';
import '../../checkin/data/checkin_repository.dart';
import '../../checkin/domain/checkin_questions.dart';
import '../../checkin/presentation/checkin_l10n.dart';
import '../../mood/data/mood_repository.dart';
import '../../mood/presentation/mood_l10n.dart';
import '../../mood/presentation/mood_providers.dart';
import '../../relapse/presentation/relapse_providers.dart';
import '../../urge/presentation/urge_providers.dart';
import 'calendar_providers.dart';

/// Bottom sheet listing every event of a tapped day: relapse, mood, check-in
/// and urges. Neutral, non-judgemental tone throughout.
class DayDetailSheet extends ConsumerWidget {
  const DayDetailSheet({required this.habitId, required this.day, super.key});

  final int habitId;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final DateTime d = dayStart(day);

    final MoodEntry? mood = ref.watch(moodForDayProvider(d)).valueOrNull;
    final CheckIn? checkin =
        ref.watch(checkinForDayProvider(habitId, d)).valueOrNull;
    final List<RelapseEvent> relapses = <RelapseEvent>[
      for (final RelapseEvent r
          in ref.watch(habitRelapsesProvider(habitId)).valueOrNull ??
              const <RelapseEvent>[])
        if (isSameDay(r.occurredAt, d)) r,
    ];
    final List<UrgeEvent> urges = <UrgeEvent>[
      for (final UrgeEvent u
          in ref.watch(urgeEventsProvider).valueOrNull ?? const <UrgeEvent>[])
        if (isSameDay(u.startedAt, d)) u,
    ];

    final bool empty =
        mood == null && checkin == null && relapses.isEmpty && urges.isEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            Text(
              DateFormat.yMMMMEEEEd(locale).format(d),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (empty)
                      Text(l10n.dayNoEvents, style: theme.textTheme.bodyMedium),
                    for (final RelapseEvent r in relapses)
                      _RelapseTile(relapse: r),
                    if (mood != null) _MoodTile(mood: mood),
                    if (checkin != null) _CheckinTile(checkin: checkin),
                    if (urges.isNotEmpty) _UrgeTile(count: urges.length),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: theme.textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _RelapseTile extends StatelessWidget {
  const _RelapseTile({required this.relapse});
  final RelapseEvent relapse;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final List<String> lines = <String>[
      if (relapse.trigger != null && relapse.trigger!.isNotEmpty)
        '${l10n.relTrigger}: ${relapse.trigger}',
      if (relapse.situation != null && relapse.situation!.isNotEmpty)
        '${l10n.relSituation}: ${relapse.situation}',
      if (relapse.note != null && relapse.note!.isNotEmpty) relapse.note!,
    ];
    return _SectionCard(
      icon: Icons.restart_alt_rounded,
      title: l10n.dayRelapseTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (lines.isEmpty)
            Text(l10n.dayRelapseLogged, style: theme.textTheme.bodyMedium)
          else
            for (final String line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(line, style: theme.textTheme.bodyMedium),
              ),
        ],
      ),
    );
  }
}

class _MoodTile extends StatelessWidget {
  const _MoodTile({required this.mood});
  final MoodEntry mood;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final List<String> tags = decodeTags(mood.tags);
    return _SectionCard(
      icon: Icons.mood_rounded,
      title: l10n.dashMoodTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                moodFaceIcon(mood.moodScore),
                color: moodColor(mood.moodScore),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                moodScoreLabel(l10n, mood.moodScore),
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${l10n.moodEnergyLabel}: ${mood.energy}/5'
            '${mood.sleepQuality != null ? '   ${l10n.moodSleepLabel}: ${mood.sleepQuality}/5' : ''}',
            style: theme.textTheme.bodyMedium,
          ),
          if (tags.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                for (final String key in tags)
                  Chip(
                    label: Text(moodTagLabel(l10n, key)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
          if (mood.note != null && mood.note!.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(mood.note!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _CheckinTile extends StatelessWidget {
  const _CheckinTile({required this.checkin});
  final CheckIn checkin;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final Map<String, dynamic> answers = decodeAnswers(checkin.answersJson);

    final List<Widget> rows = <Widget>[];
    for (final Question q in standardCheckin) {
      final dynamic v = answers[q.id];
      final String? formatted = _formatAnswer(l10n, q, v);
      if (formatted == null) continue;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            '${checkinQuestionLabel(l10n, q.id)}: $formatted',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return _SectionCard(
      icon: Icons.task_alt_rounded,
      title: l10n.dashCheckinTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows.isEmpty
            ? <Widget>[
                Text(l10n.dashCheckinDone, style: theme.textTheme.bodyMedium),
              ]
            : rows,
      ),
    );
  }

  String? _formatAnswer(AppLocalizations l10n, Question q, dynamic value) {
    if (value == null) return null;
    switch (q.type) {
      case QuestionType.yesNo:
        if (value is! bool) return null;
        return value ? l10n.commonYes : l10n.commonNo;
      case QuestionType.scale:
        if (value is! int) return null;
        return '$value/${q.scaleMax}';
      case QuestionType.multiSelect:
        if (value is! List) return null;
        final List<String> keys = value.whereType<String>().toList();
        if (keys.isEmpty) return null;
        return keys.map((String k) => checkinOptionLabel(l10n, k)).join(', ');
      case QuestionType.freeText:
        final String text = value.toString().trim();
        return text.isEmpty ? null : text;
    }
  }
}

class _UrgeTile extends StatelessWidget {
  const _UrgeTile({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return _SectionCard(
      icon: Icons.waves_rounded,
      title: l10n.urgeTitle,
      child: Text(l10n.dayUrgeCount(count), style: theme.textTheme.bodyMedium),
    );
  }
}
