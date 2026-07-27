import 'package:clean_tracker/app/app.dart';
import 'package:clean_tracker/core/db/database.dart';
import 'package:clean_tracker/core/prefs/preferences_provider.dart';
import 'package:clean_tracker/core/utils/clock.dart';
import 'package:clean_tracker/features/tracker/presentation/tracker_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('relapse flow opens from the card menu and can be cancelled',
      (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();
    final clock = FakeClock(DateTime.utc(2026, 1, 10, 12));

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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Open the card overflow menu and choose "log a relapse".
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Rückfall eintragen').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Erst mal durchatmen'), findsOneWidget);

    // Cancel returns to the dashboard without recording anything.
    await tester.tap(find.text('Doch nicht nötig'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Beer'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
