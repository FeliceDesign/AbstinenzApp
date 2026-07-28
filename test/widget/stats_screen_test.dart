import 'package:clean_tracker/core/db/database.dart';
import 'package:clean_tracker/core/db/database_provider.dart';
import 'package:clean_tracker/core/utils/clock.dart';
import 'package:clean_tracker/features/stats/presentation/stats_screen.dart';
import 'package:clean_tracker/features/tracker/presentation/tracker_providers.dart';
import 'package:clean_tracker/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('stats screen renders empty observations with no data',
      (WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const <Locale>[Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final AppDatabase db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final FakeClock clock = FakeClock(DateTime(2026, 1, 10, 12));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          databaseProvider.overrideWith((ref) => db),
          clockProvider.overrideWith((ref) => clock),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('de'),
          home: StatsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Statistik'), findsOneWidget);
    expect(
      find.textContaining('Noch keine Stimmungseinträge'),
      findsOneWidget,
    );
    // Range toggle is present.
    expect(find.text('30 Tage'), findsOneWidget);
  });
}
