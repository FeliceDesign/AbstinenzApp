import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/dates.dart';
import '../../../l10n/app_localizations.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../domain/mood_stats.dart';
import 'mood_l10n.dart';
import 'mood_providers.dart';

/// Dashboard mood card: a 7-day sparkline plus a shortcut into today's entry.
///
/// A hand-drawn [CustomPainter] rather than a chart dependency here — seven
/// points need no axes, and it keeps the dashboard light. The full history uses
/// the proper chart on the stats tab.
class DashboardMoodCard extends ConsumerWidget {
  const DashboardMoodCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final DateTime today = dayStart(ref.watch(clockProvider).now());
    final List<MoodDay> days = ref.watch(moodDaysProvider);
    final List<MoodPoint> week =
        moodSeries(days, addDays(today, -6), today);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.push('/mood-entry'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.mood_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l10n.dashMoodTitle, style: theme.textTheme.labelMedium),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (week.isEmpty)
                Text(
                  l10n.dashMoodEmpty,
                  style: theme.textTheme.bodyMedium,
                )
              else
                SizedBox(
                  height: 56,
                  child: Semantics(
                    label: l10n.dashMoodSemantics(week.length),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _SparklinePainter(
                        points: week,
                        lineColor: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.points, required this.lineColor});

  final List<MoodPoint> points;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Fixed 1..5 domain so the line height reads as absolute mood, not relative.
    const double minY = 1;
    const double maxY = 5;
    final int n = points.length;

    double dx(int i) =>
        n == 1 ? size.width / 2 : size.width * (i / (n - 1));
    double dy(int score) =>
        size.height - ((score - minY) / (maxY - minY)) * size.height;

    final Path path = Path();
    for (int i = 0; i < n; i++) {
      final Offset p = Offset(dx(i), dy(points[i].score));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    final Paint line = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, line);

    // Dots carry the mood colour — so the warm/cool meaning survives even for a
    // single point where there is no line to read.
    for (int i = 0; i < n; i++) {
      final Offset p = Offset(dx(i), dy(points[i].score));
      canvas.drawCircle(
        p,
        3,
        Paint()..color = moodColor(points[i].score),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.points != points || old.lineColor != lineColor;
}
