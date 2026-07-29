import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/home_widget/home_widget_service.dart';
import '../features/onboarding/domain/onboarding_gate.dart';
import '../features/settings/presentation/app_lock_gate.dart';
import '../features/settings/presentation/settings_providers.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';

/// The router is created once and kept alive for the app's lifetime.
final routerProvider = Provider((ref) {
  return buildRouter(ref.watch(onboardingGateProvider));
});

class CleanTrackerApp extends ConsumerStatefulWidget {
  const CleanTrackerApp({super.key});

  @override
  ConsumerState<CleanTrackerApp> createState() => _CleanTrackerAppState();
}

class _CleanTrackerAppState extends ConsumerState<CleanTrackerApp> {
  @override
  void initState() {
    super.initState();
    // Route home-screen widget taps: the urge widget deep-links into the urge
    // flow; the others just bring the app forward (already the dashboard).
    HomeWidgetService.registerClickHandler(_onWidgetUri);
  }

  void _onWidgetUri(Uri uri) {
    if (!mounted) return;
    if (uri.host == HomeWidgetService.hostUrge) {
      // The router's redirect handles the not-yet-onboarded case.
      ref.read(routerProvider).push(AppRoutes.urge);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode mode = ref.watch(themeModeSettingProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Optional biometric/passcode gate over the whole app.
      builder: (context, child) =>
          AppLockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
