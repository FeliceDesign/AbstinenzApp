import 'package:clean_tracker/app/app.dart';
import 'package:clean_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots to the empty dashboard', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CleanTrackerApp()),
    );
    await tester.pumpAndSettle();

    // Empty-state welcome copy is shown (English fallback locale in tests).
    final AppLocalizations en = await AppLocalizations.delegate.load(
      const Locale('en'),
    );
    expect(find.text(en.dashboardEmptyTitle), findsOneWidget);

    // Bottom navigation has all five destinations.
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });
}
