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
    return FloatingActionButton.extended(
      backgroundColor: AppColors.brandBerry,
      foregroundColor: Colors.white,
      onPressed: () => context.push('/urge'),
      icon: const Icon(Icons.bolt_rounded),
      label: Text(l10n.urgeFab),
    );
  }
}
