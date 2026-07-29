import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A friendly empty state that is also a call to action.
///
/// The guiding rule (see the redesign brief): an empty state should never be a
/// dead end — it names what's missing and offers the one action that fills it.
/// Icon + message + a primary pill button, centred with generous breathing room.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.actionIcon = Icons.add_rounded,
    super.key,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // A plain min-height column (no Center), so it drops safely into both a
    // bounded parent and an unbounded scroll view. Callers that want it centred
    // vertically wrap it in a Center themselves.
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandGold.withValues(alpha: 0.28),
            ),
            child: Icon(icon, size: 32, color: AppColors.brandBerry),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon, size: 18),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
