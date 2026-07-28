import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/placeholder_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/onboarding/domain/onboarding_gate.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/relapse/presentation/relapse_flow_screen.dart';
import '../features/urge/presentation/urge_fab.dart';
import '../features/urge/presentation/urge_flow_screen.dart';
import '../l10n/app_localizations.dart';

/// App routes. Declarative and deep-linkable via go_router.
///
/// Rationale for a `StatefulShellRoute`: the bottom-nav destinations each keep
/// their own navigation stack and state when switching tabs — the alternative,
/// swapping a single body widget, loses scroll position and in-progress flows.
class AppRoutes {
  const AppRoutes._();
  static const String onboarding = '/onboarding';
  static const String relapse = '/relapse';
  static const String urge = '/urge';
  static const String dashboard = '/';
  static const String calendar = '/calendar';
  static const String toolkit = '/toolkit';
  static const String stats = '/stats';
  static const String more = '/more';
}

/// Builds the router. Takes the [OnboardingGate] so it can both redirect
/// un-onboarded users into the flow and refresh when onboarding completes.
GoRouter buildRouter(OnboardingGate gate) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: gate,
    redirect: (context, state) {
      final bool onboarded = gate.isComplete;
      final bool atOnboarding =
          state.matchedLocation == AppRoutes.onboarding;
      if (!onboarded) return atOnboarding ? null : AppRoutes.onboarding;
      if (atOnboarding) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.relapse}/:habitId',
        builder: (context, state) => RelapseFlowScreen(
          habitId: int.parse(state.pathParameters['habitId']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.urge,
        builder: (context, state) => const UrgeFlowScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _ScaffoldWithNav(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calendar,
                builder: (context, state) => PlaceholderScreen(
                  title: AppLocalizations.of(context).navCalendar,
                  icon: Icons.calendar_month_rounded,
                  message: AppLocalizations.of(context).comingSoon,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.toolkit,
                builder: (context, state) => PlaceholderScreen(
                  title: AppLocalizations.of(context).navToolkit,
                  icon: Icons.spa_rounded,
                  message: AppLocalizations.of(context).comingSoon,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.stats,
                builder: (context, state) => PlaceholderScreen(
                  title: AppLocalizations.of(context).navStats,
                  icon: Icons.insights_rounded,
                  message: AppLocalizations.of(context).comingSoon,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                builder: (context, state) => PlaceholderScreen(
                  title: AppLocalizations.of(context).navMore,
                  icon: Icons.more_horiz_rounded,
                  message: AppLocalizations.of(context).comingSoon,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _ScaffoldWithNav extends StatelessWidget {
  const _ScaffoldWithNav({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      floatingActionButton: const UrgeFab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.navDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month_rounded),
            label: l10n.navCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.spa_outlined),
            selectedIcon: const Icon(Icons.spa_rounded),
            label: l10n.navToolkit,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights_rounded),
            label: l10n.navStats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz_outlined),
            selectedIcon: const Icon(Icons.more_horiz_rounded),
            label: l10n.navMore,
          ),
        ],
      ),
    );
  }
}
