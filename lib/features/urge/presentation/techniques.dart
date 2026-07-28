import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/safety/help_contacts.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../motivation/presentation/motivation_widgets.dart';
import '../domain/urge_technique.dart';

/// Renders the content for a chosen [UrgeTechnique]. Each technique is
/// self-contained; the surrounding flow provides the "how strong is it now?"
/// step, so techniques don't need completion callbacks.
Widget buildTechnique(UrgeTechnique technique) => switch (technique) {
      UrgeTechnique.urgeSurfing => const _UrgeSurfing(),
      UrgeTechnique.breathing478 => const _Breathing478(),
      UrgeTechnique.fifteenMinute => const _FifteenMinute(),
      UrgeTechnique.grounding54321 => const _Grounding(),
      UrgeTechnique.playTheTape => const _PlayTheTape(),
      UrgeTechnique.distraction => const _Distraction(),
      UrgeTechnique.emergencyContact => const _EmergencyContact(),
    };

String techniqueName(AppLocalizations l10n, UrgeTechnique t) => switch (t) {
      UrgeTechnique.urgeSurfing => l10n.techUrgeSurfing,
      UrgeTechnique.breathing478 => l10n.techBreathing478,
      UrgeTechnique.fifteenMinute => l10n.techFifteenMinute,
      UrgeTechnique.grounding54321 => l10n.techGrounding,
      UrgeTechnique.playTheTape => l10n.techPlayTheTape,
      UrgeTechnique.distraction => l10n.techDistraction,
      UrgeTechnique.emergencyContact => l10n.techEmergencyContact,
    };

// --- Urge surfing ------------------------------------------------------------

class _UrgeSurfing extends StatefulWidget {
  const _UrgeSurfing();

  @override
  State<_UrgeSurfing> createState() => _UrgeSurfingState();
}

class _UrgeSurfingState extends State<_UrgeSurfing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(minutes: 3),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lines = [l10n.surfLine1, l10n.surfLine2, l10n.surfLine3];

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final int i =
            (_c.value * lines.length).clamp(0, lines.length - 1).floor();
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.waves_rounded,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.xl),
            AnimatedSwitcher(
              duration: AppMotion.base,
              child: Text(
                lines[i],
                key: ValueKey(i),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            LinearProgressIndicator(
              value: _c.value,
              minHeight: 6,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ],
        );
      },
    );
  }
}

// --- 4-7-8 breathing ---------------------------------------------------------

class _Breathing478 extends StatefulWidget {
  const _Breathing478();

  @override
  State<_Breathing478> createState() => _Breathing478State();
}

class _Breathing478State extends State<_Breathing478>
    with SingleTickerProviderStateMixin {
  // Phases: inhale 4s, hold 7s, exhale 8s.
  static const List<int> _durations = [4, 7, 8];
  late final AnimationController _c;
  int _phase = 0;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _c.addStatusListener(_onStatus);
    _c.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed &&
        status != AnimationStatus.dismissed) {
      return;
    }
    HapticFeedback.lightImpact();
    final int next = (_phase + 1) % 3;
    setState(() => _phase = next);
    _c.duration = Duration(seconds: _durations[next]);
    // Inhale expands, exhale/hold shrink or hold — drive the circle by phase.
    if (next == 0) {
      _c.forward(from: 0); // inhale
    } else if (next == 2) {
      _c.reverse(from: 1); // exhale
    } else {
      _c.value = 1; // hold (stay expanded), wait then advance
      Future.delayed(Duration(seconds: _durations[1]), () {
        if (mounted && _phase == 1) _onStatus(AnimationStatus.completed);
      });
    }
  }

  @override
  void dispose() {
    _c.removeStatusListener(_onStatus);
    _c.dispose();
    super.dispose();
  }

  String _label(AppLocalizations l10n) => switch (_phase) {
        0 => l10n.breatheIn,
        1 => l10n.breatheHold,
        _ => l10n.breatheOut,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final double scale = 0.6 + 0.4 * _c.value;
            return Container(
              width: 200 * scale,
              height: 200 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.brandSky, AppColors.brandSkyLight],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandSky.withValues(alpha: 0.25),
                    blurRadius: 40,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(_label(l10n), style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.breatheHint, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

// --- 15-minute rule ----------------------------------------------------------

class _FifteenMinute extends StatefulWidget {
  const _FifteenMinute();

  @override
  State<_FifteenMinute> createState() => _FifteenMinuteState();
}

class _FifteenMinuteState extends State<_FifteenMinute> {
  Duration _remaining = const Duration(minutes: 15);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (_remaining <= Duration.zero) {
          _remaining = Duration.zero;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mmss =
        '${_remaining.inMinutes.toString().padLeft(2, '0')}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.hourglass_bottom_rounded,
          size: 48,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          mmss,
          style: theme.textTheme.displayLarge
              ?.copyWith(fontFeatures: AppFonts.tabular),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.fifteenHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}

// --- 5-4-3-2-1 grounding -----------------------------------------------------

class _Grounding extends StatefulWidget {
  const _Grounding();

  @override
  State<_Grounding> createState() => _GroundingState();
}

class _GroundingState extends State<_Grounding> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final steps = [
      l10n.groundSee,
      l10n.groundHear,
      l10n.groundFeel,
      l10n.groundSmell,
      l10n.groundTaste,
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${5 - _step}',
          style: theme.textTheme.displayLarge
              ?.copyWith(color: theme.colorScheme.primary),
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedSwitcher(
          duration: AppMotion.base,
          child: Text(
            steps[_step],
            key: ValueKey(_step),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (_step < steps.length - 1)
          OutlinedButton(
            onPressed: () => setState(() => _step++),
            child: Text(l10n.urgeNext),
          )
        else
          Text(l10n.groundDone, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

// --- Play the tape forward ---------------------------------------------------

class _PlayTheTape extends StatelessWidget {
  const _PlayTheTape();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Shows the user's own consequences + why (Phase 4 integration); falls back
    // to a guided prompt when nothing has been entered yet.
    return ListView(
      children: [
        Icon(
          Icons.movie_outlined,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.tapeBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xl),
        const MotivationRecall(showConsequences: true, showWhy: true),
      ],
    );
  }
}

// --- Distraction list --------------------------------------------------------

class _Distraction extends StatefulWidget {
  const _Distraction();

  @override
  State<_Distraction> createState() => _DistractionState();
}

class _DistractionState extends State<_Distraction> {
  final Random _rng = Random();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final activities = [
      l10n.distract1,
      l10n.distract2,
      l10n.distract3,
      l10n.distract4,
      l10n.distract5,
      l10n.distract6,
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(l10n.distractHint, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        AnimatedSwitcher(
          duration: AppMotion.base,
          child: Text(
            activities[_index],
            key: ValueKey(_index),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        OutlinedButton.icon(
          onPressed: () => setState(
            () => _index = _rng.nextInt(activities.length),
          ),
          icon: const Icon(Icons.shuffle_rounded, size: 18),
          label: Text(l10n.distractAnother),
        ),
      ],
    );
  }
}

// --- Emergency contact -------------------------------------------------------

class _EmergencyContact extends StatelessWidget {
  const _EmergencyContact();

  Future<void> _call(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).emergencyCallError),
        ),
      );
    }
  }

  String _label(AppLocalizations l10n, String key) => switch (key) {
        'helpTelefonseelsorge1' => l10n.helpTelefonseelsorge1,
        'helpTelefonseelsorge2' => l10n.helpTelefonseelsorge2,
        'helpSuchtHotline' => l10n.helpSuchtHotline,
        _ => l10n.helpEmergency,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      shrinkWrap: true,
      children: [
        Text(l10n.emergencyHint, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        for (final c in kHelpContactsDe)
          Card(
            child: ListTile(
              leading: const Icon(Icons.call_rounded),
              title: Text(_label(l10n, c.labelKey)),
              subtitle: Text(c.number),
              onTap: () => _call(context, c.number),
            ),
          ),
      ],
    );
  }
}
