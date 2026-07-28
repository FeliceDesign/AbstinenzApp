import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/prefs/preferences_provider.dart';
import '../data/data_repository.dart';

part 'settings_providers.g.dart';

@riverpod
DataRepository dataRepository(DataRepositoryRef ref) =>
    DataRepository(ref.watch(databaseProvider));

/// The app's theme mode. Defaults to following the system (light-first per the
/// style guide — the OS decides, with a manual override here). Persisted.
@riverpod
class ThemeModeSetting extends _$ThemeModeSetting {
  static const String _key = 'theme_mode';

  @override
  ThemeMode build() {
    final String? v = ref.watch(sharedPreferencesProvider).getString(_key);
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
    state = mode;
  }
}

/// Whether the optional biometric/passcode app lock is enabled. Persisted.
@riverpod
class AppLockEnabled extends _$AppLockEnabled {
  static const String _key = 'app_lock_enabled';

  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> set({required bool value}) async {
    await ref.read(sharedPreferencesProvider).setBool(_key, value);
    state = value;
  }
}
