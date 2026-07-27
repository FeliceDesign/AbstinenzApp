import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';

/// App-wide theme mode. Dark is the design default; persistence to
/// shared_preferences is wired up in the settings phase.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// The router is created once and kept alive for the app's lifetime.
final routerProvider = Provider((ref) => buildRouter());

class CleanTrackerApp extends ConsumerWidget {
  const CleanTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
