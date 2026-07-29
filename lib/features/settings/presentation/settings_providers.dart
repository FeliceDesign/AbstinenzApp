import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// The daily mood/check-in reminder configuration. Persisted.
@immutable
class ReminderConfig {
  const ReminderConfig({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;

  ReminderConfig copyWith({bool? enabled, int? hour, int? minute}) =>
      ReminderConfig(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  @override
  bool operator ==(Object other) =>
      other is ReminderConfig &&
      other.enabled == enabled &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(enabled, hour, minute);
}

/// The evening reminder that nudges the user to log mood + check-in. On by
/// default at 21:00; both the on/off flag and the time are persisted.
@riverpod
class DailyReminderSetting extends _$DailyReminderSetting {
  static const String _enabledKey = 'reminder_enabled';
  static const String _hourKey = 'reminder_hour';
  static const String _minuteKey = 'reminder_minute';

  @override
  ReminderConfig build() {
    final SharedPreferences p = ref.watch(sharedPreferencesProvider);
    return ReminderConfig(
      enabled: p.getBool(_enabledKey) ?? true,
      hour: p.getInt(_hourKey) ?? 21,
      minute: p.getInt(_minuteKey) ?? 0,
    );
  }

  Future<void> setEnabled({required bool value}) async {
    await ref.read(sharedPreferencesProvider).setBool(_enabledKey, value);
    state = state.copyWith(enabled: value);
  }

  Future<void> setTime({required int hour, required int minute}) async {
    final SharedPreferences p = ref.read(sharedPreferencesProvider);
    await p.setInt(_hourKey, hour);
    await p.setInt(_minuteKey, minute);
    state = state.copyWith(hour: hour, minute: minute);
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
