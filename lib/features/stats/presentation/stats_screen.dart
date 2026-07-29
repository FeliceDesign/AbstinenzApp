import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/color_field_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../checkin/presentation/checkin_providers.dart';
import '../../mood/domain/mood_stats.dart';
import '../../mood/presentation/mood_l10n.dart';
import '../../mood/presentation/mood_providers.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../../urge/domain/urge_stats.dart';
import '../../urge/presentation/techniques.dart';
import '../../urge/presentation/urge_providers.dart';

/// The "Statistik" tab. Mood history (chart), the gentle check-in streak, and
/// honest, non-clinical observations about mood around urges and hard days.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _rangeDays = 30;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DateTime today = dayStart(ref.watch(clockProvider).now());
    final DateTime from = addDays(today, -(_rangeDays - 1));
    final List<MoodDay> moods = ref.watch(moodDaysProvider);
    final List<MoodPoint> series = moodSeries(moods, from, today);
    final double? avg = averageScore(series.map((MoodPoint p) => p.score));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: <Widget>[
            _RangeToggle(
              value: _rangeDays,
              onChanged: (int v) => setState(() => _rangeDays = v),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionTitle(text: l10n.statsMoodSection),
            const SizedBox(height: AppSpacing.md),
            if (series.isEmpty)
              EmptyState(
                icon: Icons.mood_rounded,
                message: l10n.statsMoodEmpty,
                actionLabel: l10n.statsLogMood,
                onAction: () => context.push('/mood-entry'),
              )
            else ...<Widget>[
              _MoodChart(series: series, from: from, to: today),
              const SizedBox(height: AppSpacing.md),
              if (avg != null)
                Text(
                  l10n.statsAvgMood(avg.toStringAsFixed(1)),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            const _CheckinStreakCard(),
            const SizedBox(height: AppSpacing.xxl),
            _SectionTitle(text: l10n.statsObservationsTitle),
            const SizedBox(height: AppSpacing.md),
            const _MoodUrgeObservation(),
            const SizedBox(height: AppSpacing.lg),
            const _MoodAroundRelapseObservation(),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.statsObservationDisclaimer,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _SectionTitle(text: l10n.statsUrgeSection),
            const SizedBox(height: AppSpacing.md),
            const _UrgeInsights(),
          ],
        ),
      ),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  const _RangeToggle({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return SegmentedButton<int>(
      segments: <ButtonSegment<int>>[
        ButtonSegment<int>(value: 7, label: Text(l10n.statsRange7)),
        ButtonSegment<int>(value: 30, label: Text(l10n.statsRange30)),
        ButtonSegment<int>(value: 90, label: Text(l10n.statsRange90)),
      ],
      selected: <int>{value},
      showSelectedIcon: false,
      onSelectionChanged: (Set<int> s) => onChanged(s.first),
    );
  }
}

class _MoodChart extends StatelessWidget {
  const _MoodChart({required this.series, required this.from, required this.to});

  final List<MoodPoint> series;
  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final double maxX = to.difference(from).inDays.toDouble();

    final List<FlSpot> spots = <FlSpot>[
      for (final MoodPoint p in series)
        FlSpot(p.day.difference(from).inDays.toDouble(), p.score.toDouble()),
    ];

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX <= 0 ? 1 : maxX,
          minY: 1,
          maxY: 5,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (double value) => FlLine(
              color: theme.colorScheme.outlineVariant,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value < 1 || value > 5) return const SizedBox.shrink();
                  return Text(
                    '${value.toInt()}',
                    style: theme.textTheme.bodySmall,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (maxX <= 0 ? 1 : maxX),
                getTitlesWidget: (double value, TitleMeta meta) {
                  final DateTime day = addDays(from, value.round());
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      DateFormat.MMMd(locale).format(day),
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: <LineChartBarData>[
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: theme.colorScheme.primary,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 3.5,
                  color: moodColor(spot.y.round()),
                  strokeWidth: 0,
                  strokeColor: Colors.transparent,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.brandSkyLight.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckinStreakCard extends ConsumerWidget {
  const _CheckinStreakCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final int streak = ref.watch(checkinStreakCountProvider);

    // The check-in streak is the achievement figure on this screen, so it gets
    // a warm gold field with dark ink text; the observation cards stay neutral.
    return ColorFieldCard(
      fill: AppColors.brandGold,
      onFill: AppColors.lightTextPrimary,
      child: Row(
        children: <Widget>[
          const Icon(Icons.event_repeat_rounded, color: AppColors.brandBerry),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              streak > 0
                  ? l10n.checkinStreakLabel(streak)
                  : l10n.statsCheckinNone,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodUrgeObservation extends ConsumerWidget {
  const _MoodUrgeObservation();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final MoodUrgeComparison c = ref.watch(moodUrgeComparisonProvider);

    if (!c.hasData) {
      return _EmptyNote(text: l10n.statsMoodUrgeEmpty);
    }
    return _ObservationCard(
      icon: Icons.compare_arrows_rounded,
      text: l10n.statsMoodUrge(
        c.avgWithUrge!.toStringAsFixed(1),
        c.avgWithoutUrge!.toStringAsFixed(1),
      ),
    );
  }
}

class _MoodAroundRelapseObservation extends ConsumerWidget {
  const _MoodAroundRelapseObservation();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<MoodOffset> offsets = ref.watch(moodAroundRelapseDaysProvider);

    final MoodOffset? before = offsets
        .where((MoodOffset o) => o.offset == -1 && o.average != null)
        .firstOrNull;
    final MoodOffset? after = offsets
        .where((MoodOffset o) => o.offset == 1 && o.average != null)
        .firstOrNull;

    if (before == null && after == null) {
      return _EmptyNote(text: l10n.statsAroundRelapseEmpty);
    }
    final String beforeText =
        before == null ? '–' : before.average!.toStringAsFixed(1);
    final String afterText =
        after == null ? '–' : after.average!.toStringAsFixed(1);
    return _ObservationCard(
      icon: Icons.timeline_rounded,
      text: l10n.statsAroundRelapse(beforeText, afterText),
    );
  }
}

class _UrgeInsights extends ConsumerWidget {
  const _UrgeInsights();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final int waves = ref.watch(wavesRiddenCountProvider);
    final List<TechniqueEffectiveness> effectiveness =
        ref.watch(techniqueEffectivenessProvider);

    if (waves == 0) {
      return _EmptyNote(text: l10n.statsUrgeEmpty);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ObservationCard(
          icon: Icons.waves_rounded,
          text: l10n.statsWaves(waves),
        ),
        if (effectiveness.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.statsWhatWorks, style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final TechniqueEffectiveness e in effectiveness)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                l10n.statsTechniqueEffect(
                  techniqueNameByKey(l10n, e.technique),
                  e.averageReduction.toStringAsFixed(1),
                  e.uses,
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
        ],
      ],
    );
  }
}

class _ObservationCard extends StatelessWidget {
  const _ObservationCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(text, style: theme.textTheme.bodyLarge),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.headlineMedium);
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      );
}
