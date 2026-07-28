import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import 'checkin_providers.dart';

/// Dashboard check-in card: shows whether today's check-in is done or open, and
/// the gentle "X in a row" streak. Tapping opens the check-in flow.
class DashboardCheckinCard extends ConsumerWidget {
  const DashboardCheckinCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final bool done = ref.watch(checkinDoneTodayProvider);
    final int streak = ref.watch(checkinStreakCountProvider);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.push('/checkin'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: <Widget>[
              Icon(
                done
                    ? Icons.task_alt_rounded
                    : Icons.checklist_rtl_rounded,
                color: done
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.dashCheckinTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      done ? l10n.dashCheckinDone : l10n.dashCheckinOpen,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (streak > 0) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.checkinStreakLabel(streak),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
