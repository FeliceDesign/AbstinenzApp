import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app's [SharedPreferences] instance.
///
/// Overridden in `main()` with the real instance loaded before `runApp`, so the
/// rest of the app can read prefs synchronously (no loading spinners for a
/// simple onboarding flag / theme mode). Throwing here makes a missing override
/// fail loudly in tests instead of silently returning null.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});
