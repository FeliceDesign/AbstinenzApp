import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/streak_calculator.dart';

/// The dashboard hero: a live `Xd  HH:MM:SS` counter since [startedAt].
///
/// Lifecycle-aware — the 1-second timer only runs while the app is in the
/// foreground (paused/inactive/hidden cancels it), so there is never a timer
/// ticking in the background. It reads "now" from the injected [clock] each
/// tick, which keeps it deterministic under a `FakeClock` in tests.
class StreakTicker extends StatefulWidget {
  const StreakTicker({
    required this.startedAt,
    required this.clock,
    this.detailed = true,
    this.onField = false,
    super.key,
  });

  final DateTime startedAt;
  final Clock clock;

  /// When false, only the day count is shown ("days only" mode).
  final bool detailed;

  /// When true the ticker sits on a coloured field (the hero card): the day
  /// label and clock switch to inverted (translucent white) so they read on
  /// the field instead of the neutral surface colour.
  final bool onField;

  @override
  State<StreakTicker> createState() => _StreakTickerState();
}

class _StreakTickerState extends State<StreakTicker>
    with WidgetsBindingObserver {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = widget.clock.now();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void didUpdateWidget(StreakTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh immediately if the underlying attempt changed.
    if (oldWidget.startedAt != widget.startedAt) {
      setState(() => _now = widget.clock.now());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = widget.clock.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final StreakParts parts = StreakParts.of(
      currentStreak(
        [AttemptSpan(startedAt: widget.startedAt)],
        _now,
      ),
    );

    final String clock =
        '${_two(parts.hours)}:${_two(parts.minutes)}:${_two(parts.seconds)}';
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final Color labelColor = widget.onField
        ? Colors.white.withValues(alpha: 0.85)
        : theme.colorScheme.onSurfaceVariant;
    final Color clockColor = widget.onField
        ? Colors.white
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      label: l10n.streakSemantics(parts.days, clock),
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress is always warm: gold -> sand gradient on the big number.
          ShaderMask(
            shaderCallback: (Rect bounds) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.brandGold, AppColors.brandSand],
            ).createShader(bounds),
            child: Text(
              '${parts.days}',
              style: theme.textTheme.displayLarge?.copyWith(
                color: Colors.white,
                fontFeatures: AppFonts.tabular,
              ),
            ),
          ),
          Text(
            l10n.streakDaysLabel(parts.days),
            style: theme.textTheme.bodyMedium?.copyWith(color: labelColor),
          ),
          if (widget.detailed) ...[
            const SizedBox(height: AppSpacing.md),
            _ClockLine(
              text: clock,
              reduceMotion: reduceMotion,
              theme: theme,
              color: clockColor,
            ),
          ],
        ],
      ),
    );
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}

class _ClockLine extends StatelessWidget {
  const _ClockLine({
    required this.text,
    required this.reduceMotion,
    required this.theme,
    required this.color,
  });

  final String text;
  final bool reduceMotion;
  final ThemeData theme;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = theme.textTheme.headlineMedium!.copyWith(
      fontFeatures: AppFonts.tabular,
      color: color,
    );
    final Widget child = Text(text, key: ValueKey(text), style: style);
    if (reduceMotion) return child;
    return AnimatedSwitcher(
      duration: AppMotion.fast,
      transitionBuilder: (widget, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(animation),
        child: FadeTransition(opacity: animation, child: widget),
      ),
      child: child,
    );
  }
}
