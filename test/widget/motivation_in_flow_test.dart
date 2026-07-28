import 'package:clean_tracker/app/app.dart';
import 'package:clean_tracker/core/db/database.dart';
import 'package:clean_tracker/core/prefs/preferences_provider.dart';
import 'package:clean_tracker/core/utils/clock.dart';
import 'package:clean_tracker/features/motivation/presentation/motivation_providers.dart';
import 'package:clean_tracker/features/motivation/presentation/motivation_widgets.dart';
import 'package:clean_tracker/features/tracker/presentation/tracker_providers.dart';
import 'package:clean_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Motivation _mot(int id, String content, MotivationKind kind) => Motivation(
      id: id,
      content: content,
      kind: kind,
      sortOrder: 0,
      isPinned: kind == MotivationKind.why,
    );

void main() {
  testWidgets('the relapse pause step surfaces the user\'s why', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();
    final clock = FakeClock(DateTime.utc(2026, 1, 10, 12));
    final why = _mot(1, 'Für meine Tochter', MotivationKind.why);

    final habit = Habit(
      id: 1,
      name: 'Beer',
      type: HabitType.alcohol,
      unitLabel: 'drink',
      isActive: true,
      createdAt: DateTime.utc(2026, 1, 7, 12),
    );
    final attempt =
        QuitAttempt(id: 1, habitId: 1, startedAt: DateTime.utc(2026, 1, 7, 12));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWith((ref) => clock),
          activeHabitsProvider.overrideWith((ref) => Stream.value([habit])),
          habitAttemptsProvider(1)
              .overrideWith((ref) => Stream.value([attempt])),
          pinnedWhysProvider.overrideWith((ref) => Stream.value([why])),
          motivationsByKindProvider(MotivationKind.why)
              .overrideWith((ref) => Stream.value([why])),
          motivationsByKindProvider(MotivationKind.benefit)
              .overrideWith((ref) => Stream.value(const [])),
          motivationsByKindProvider(MotivationKind.consequence)
              .overrideWith((ref) => Stream.value(const [])),
        ],
        child: const CleanTrackerApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Rückfall eintragen').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // On the pause step, the person's own why is shown back to them.
    expect(find.text('Erst mal durchatmen'), findsOneWidget);
    expect(find.text('Für meine Tochter'), findsAtLeastNWidgets(1));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('MotivationRecall lists why and consequences (play-the-tape)',
      (tester) async {
    final why = _mot(1, 'Ich will wieder atmen', MotivationKind.why);
    final cons = _mot(2, 'Ich verliere Vertrauen', MotivationKind.consequence);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          motivationsByKindProvider(MotivationKind.why)
              .overrideWith((ref) => Stream.value([why])),
          motivationsByKindProvider(MotivationKind.consequence)
              .overrideWith((ref) => Stream.value([cons])),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MotivationRecall(showConsequences: true, showWhy: true),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Ich will wieder atmen'), findsOneWidget);
    expect(find.text('Ich verliere Vertrauen'), findsOneWidget);
  });
}
