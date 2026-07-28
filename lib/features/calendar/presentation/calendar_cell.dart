import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../mood/presentation/mood_l10n.dart';
import '../domain/calendar_day.dart';

/// Opacity ramp for clean-day warmth (see design spec: 25/45/70/100 %).
const List<double> _warmthOpacity = <double>[0.25, 0.45, 0.70, 1.0];

/// One heatmap cell. Encodes, at a glance:
///  - background: clean (gold, warmer with a longer streak) / relapse (outlined,
///    no fill, no red) / nothing,
///  - a mood dot (bottom centre) in the mood colour,
///  - a thin sky ring when the day's check-in was completed.
///
/// Colour is never the only signal: the day number is always shown, relapse
/// days carry an outline, and check-in adds a distinct ring shape.
class CalendarCell extends StatelessWidget {
  const CalendarCell({required this.day, required this.onTap, super.key});

  final CalendarDay day;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final Color fill;
    final Color textColor;
    switch (day.status) {
      case DayStatus.clean:
        final int tier = warmthTier(day.cleanRun);
        fill = AppColors.brandGold.withValues(alpha: _warmthOpacity[tier]);
        // Bright gold needs dark text; faint gold over the surface keeps normal.
        textColor =
            tier >= 2 ? AppColors.lightTextPrimary : scheme.onSurface;
      case DayStatus.relapse:
        fill = scheme.surfaceContainer;
        textColor = scheme.onSurfaceVariant;
      case DayStatus.none:
        fill = day.inFuture
            ? scheme.surfaceContainerLowest
            : scheme.surfaceContainerLow;
        textColor = day.inFuture
            ? scheme.onSurfaceVariant.withValues(alpha: 0.4)
            : scheme.onSurfaceVariant;
    }

    // Relapse = outline (no fill). Check-in = sky ring (takes visual priority).
    final Border? border = day.checkinDone
        ? Border.all(color: AppColors.brandSky, width: 1.5)
        : day.status == DayStatus.relapse
            ? Border.all(color: scheme.outline)
            : null;

    return Semantics(
      button: onTap != null,
      label: _semanticLabel(context),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: border,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Text(
                '${day.date.day}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontFeatures: AppFonts.tabular,
                ),
              ),
              if (day.moodScore != null)
                Align(
                  alignment: const Alignment(0, 0.72),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: moodColor(day.moodScore!),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _semanticLabel(BuildContext context) {
    final String status = switch (day.status) {
      DayStatus.clean => 'clean',
      DayStatus.relapse => 'relapse',
      DayStatus.none => '',
    };
    return '${day.date.day}. $status'.trim();
  }
}
