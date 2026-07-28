import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../checkin/presentation/checkin_card.dart';
import '../../mood/presentation/mood_sparkline.dart';
import '../../motivation/presentation/motivation_widgets.dart';
import '../../savings/presentation/savings_tiles.dart';
import '../../tracker/presentation/habit_streak_card.dart';
import '../../tracker/presentation/tracker_providers.dart';

/// Dashboard / start screen.
///
/// Phase 1 shows the live time tracker per active habit. The remaining hero
/// elements (next milestone ring, savings/calorie tiles, "your why" card,
/// check-in card, mood sparkline, urge FAB) arrive in later phases.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final habitsAsync = ref.watch(activeHabitsProvider);

    return Scaffold(
      body: SafeArea(
        child: habitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.genericError)),
          data: (habits) {
            if (habits.isEmpty) return const _EmptyDashboard();
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.md,
                    ),
                    child: Text(
                      l10n.appTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
                if (habits.length == 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: HabitStreakCard(habit: habits.first),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: _HabitCarousel(habits: habits),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.lg),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: DashboardSavingsTiles(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.lg),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: DashboardWhyCard(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.lg),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: DashboardCheckinCard(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.lg),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: DashboardMoodCard(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Horizontal, swipeable cards when several habits are tracked in parallel.
class _HabitCarousel extends StatelessWidget {
  const _HabitCarousel({required this.habits});
  final List<Habit> habits;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: habits.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: HabitStreakCard(habit: habits[i]),
        ),
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
    );
  }
}
