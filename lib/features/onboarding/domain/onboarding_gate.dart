import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/prefs/preferences_provider.dart';

/// Tracks whether first-run onboarding has been completed.
///
/// A [ChangeNotifier] (rather than a Riverpod state object) so it can double as
/// the go_router `refreshListenable`: completing onboarding notifies the router,
/// which re-evaluates its redirect and leaves the onboarding flow.
class OnboardingGate extends ChangeNotifier {
  OnboardingGate(this._prefs);

  static const String _key = 'onboarding_complete';
  final SharedPreferences _prefs;

  bool get isComplete => _prefs.getBool(_key) ?? false;

  Future<void> markComplete() async {
    await _prefs.setBool(_key, true);
    notifyListeners();
  }

  /// Used by "reset all data" later; kept here next to the flag it owns.
  Future<void> reset() async {
    await _prefs.remove(_key);
    notifyListeners();
  }
}

final onboardingGateProvider = ChangeNotifierProvider<OnboardingGate>((ref) {
  return OnboardingGate(ref.watch(sharedPreferencesProvider));
});
