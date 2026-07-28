import 'package:clean_tracker/app/app.dart';
import 'package:clean_tracker/core/db/database.dart';
import 'package:clean_tracker/core/db/database_provider.dart';
import 'package:clean_tracker/core/prefs/preferences_provider.dart';
import 'package:clean_tracker/core/utils/clock.dart';
import 'package:clean_tracker/features/tracker/presentation/tracker_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('fresh install lands on onboarding', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) => db),
        ],
        child: const CleanTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Willkommen bei Chainless'), findsOneWidget);
    expect(find.text('Übersicht'), findsNothing); // nav not shown yet
  });

  testWidgets('onboarded install shows the live streak on the dashboard',
      (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();
    final clock = FakeClock(DateTime.utc(2026, 1, 10, 12));

    // A habit whose streak started exactly 3 days before "now". Fed to the UI
    // as plain streams so the test avoids the drift engine (and its async
    // timers) entirely — the only timer left is the ticker's, cancelled on
    // unmount below.
    final habit = Habit(
      id: 1,
      name: 'Beer',
      type: HabitType.alcohol,
      unitLabel: 'drink',
      isActive: true,
      createdAt: DateTime.utc(2026, 1, 7, 12),
    );
    final attempt = QuitAttempt(
      id: 1,
      habitId: 1,
      startedAt: DateTime.utc(2026, 1, 7, 12),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWith((ref) => clock),
          activeHabitsProvider.overrideWith((ref) => Stream.value([habit])),
          habitAttemptsProvider(1)
              .overrideWith((ref) => Stream.value([attempt])),
        ],
        child: const CleanTrackerApp(),
      ),
    );
    await tester.pump(); // build
    await tester.pump(const Duration(milliseconds: 50)); // streams emit

    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(find.text('Beer'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // day count

    // Unmount so the ticker's periodic timer is cancelled before test end.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
