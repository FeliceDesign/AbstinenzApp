import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Dashboard / start screen.
///
/// Phase 0 shows an empty state only. The full layout (streak ticker, next
/// milestone ring, savings/calorie tiles, "your why" card, check-in card, mood
/// sparkline, urge FAB) is built out in later phases.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: Text(l10n.appTitle, style: theme.textTheme.titleLarge),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Soft brand glow around the empty hero, previewing where
                    // the streak ticker will live.
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.brandGold, AppColors.brandSand],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandGold.withValues(alpha: 0.18),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.wb_twilight_rounded,
                        size: 44,
                        color: AppColors.darkBgBase,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.dashboardEmptyTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.dashboardEmptyBody,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
