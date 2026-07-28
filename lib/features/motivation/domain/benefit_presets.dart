import '../../../core/db/database.dart';

/// Tappable benefit suggestions offered per habit type. Values are
/// AppLocalizations keys resolved in the widget layer (content is localized).
///
/// Each list = a few generic benefits plus type-specific ones for the common
/// types. Users adopt any of these into their own list or write their own.
List<String> benefitPresetKeys(HabitType type) {
  const generic = <String>[
    'benGenClearHead',
    'benGenMoney',
    'benGenSleep',
    'benGenPride',
  ];
  final specific = switch (type) {
    HabitType.nicotine => <String>['benNicBreath', 'benNicTaste', 'benNicSkin'],
    HabitType.alcohol => <String>['benAlcSleep', 'benAlcLiver', 'benAlcMood'],
    HabitType.cannabis => <String>['benCanFocus', 'benCanMotivation'],
    HabitType.sugar => <String>['benSugEnergy', 'benSugTeeth'],
    HabitType.gaming => <String>['benGamTime', 'benGamPosture'],
    HabitType.porn => <String>['benPornPresence', 'benPornConnection'],
    HabitType.other => <String>[],
  };
  return [...specific, ...generic];
}
