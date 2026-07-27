import 'package:clean_tracker/app/app.dart';
import 'package:clean_tracker/core/db/database.dart';
import 'package:clean_tracker/core/db/database_provider.dart';
import 'package:clean_tracker/core/prefs/preferences_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('changing the tracked substance refreshes the name field',
      (tester) async {
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

    // Welcome -> habit step.
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    TextField nameField() => tester.widget<TextField>(
          find.ancestor(
            of: find.text('Name'),
            matching: find.byType(TextField),
          ),
        );

    // Pick Alcohol: the name field auto-fills.
    await tester.tap(find.text('Alkohol'));
    await tester.pumpAndSettle();
    expect(nameField().controller!.text, 'Alkohol');

    // Switch to Nicotine: the (still-default) name field must update — this is
    // the reported bug.
    await tester.tap(find.text('Nikotin'));
    await tester.pumpAndSettle();
    expect(nameField().controller!.text, 'Nikotin');
  });
}
