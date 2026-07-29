import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// The always-present "I have an urge" button, in the signal colour berry.
/// Present on every main screen; opens the urge toolkit flow.
class UrgeFab extends StatelessWidget {
  const UrgeFab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The flat berry goes muddy on the warm-dark ground, so in dark mode the
    // urge signal is lifted (style guide §5.1) to keep this — the app's most
    // important escape hatch — instantly legible.
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return FloatingActionButton.extended(
      backgroundColor: dark ? AppColors.brandBerryLifted : AppColors.brandBerry,
      foregroundColor: Colors.white,
      onPressed: () => context.push('/urge'),
      icon: const Icon(Icons.bolt_rounded),
      label: Text(l10n.urgeFab),
    );
  }
}
