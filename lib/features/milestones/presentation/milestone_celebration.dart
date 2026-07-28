import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Full-screen milestone celebration: a single calm radial gold wave from the
/// centre (~900 ms, no confetti), the milestone, and a shareable graphic.
class MilestoneCelebrationScreen extends StatefulWidget {
  const MilestoneCelebrationScreen({
    required this.title,
    required this.subtitle,
    required this.habitName,
    super.key,
  });

  final String title;
  final String subtitle;
  final String habitName;

  @override
  State<MilestoneCelebrationScreen> createState() =>
      _MilestoneCelebrationScreenState();
}

class _MilestoneCelebrationScreenState extends State<MilestoneCelebrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;
  final ScreenshotController _shot = ScreenshotController();
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(vsync: this, duration: AppMotion.slow);
    // Start the wave after the first frame (respect reduce-motion later).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!MediaQuery.of(context).disableAnimations) _wave.forward();
    });
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final Uint8List bytes = await _shot.captureFromWidget(
        _ShareCard(
          title: widget.title,
          subtitle: widget.subtitle,
          habitName: widget.habitName,
        ),
        context: context,
        pixelRatio: 3,
      );
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/milestone.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(<XFile>[XFile(file.path)]);
    } catch (_) {
      // Sharing cancelled or unavailable — nothing to do.
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _wave,
              builder: (BuildContext context, Widget? child) => CustomPaint(
                painter: _WavePainter(progress: _wave.value),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 64,
                    color: AppColors.brandGold,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  FilledButton.icon(
                    onPressed: _sharing ? null : _share,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: Text(l10n.msShare),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(l10n.commonClose),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The graphic that gets captured and shared. Self-contained and fixed-size so
/// it renders identically off-screen.
class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.title,
    required this.subtitle,
    required this.habitName,
  });

  final String title;
  final String subtitle;
  final String habitName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      height: 380,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.brandGold, AppColors.brandSand],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.emoji_events_rounded,
            size: 56,
            color: AppColors.darkBgBase,
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 40,
              height: 1.0,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBgBase,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 18,
              color: AppColors.darkBgBase,
            ),
          ),
          const Spacer(),
          Text(
            habitName,
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBgBase,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single expanding, fading gold ring from the centre.
class _WavePainter extends CustomPainter {
  const _WavePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final Offset center = size.center(Offset.zero);
    final double maxR = size.longestSide * 0.75;
    final double r = maxR * progress;
    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.brandGold.withValues(alpha: 0.18 * (1 - progress));
    canvas.drawCircle(center, r, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.progress != progress;
}
