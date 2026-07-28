import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/prefs/preferences_provider.dart';

/// Stores the free-text "letter to my future self". A single string in
/// shared_preferences — it's one document, not relational data, so it doesn't
/// belong in the database.
class FutureLetterStore {
  FutureLetterStore(this._prefs);

  static const String _key = 'future_letter';
  final SharedPreferences _prefs;

  String get text => _prefs.getString(_key) ?? '';

  Future<void> save(String value) => _prefs.setString(_key, value);
}

final futureLetterStoreProvider = Provider<FutureLetterStore>((ref) {
  return FutureLetterStore(ref.watch(sharedPreferencesProvider));
});
