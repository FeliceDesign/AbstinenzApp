import 'package:flutter/material.dart';

import '../../../core/db/database.dart';

/// Presentation helpers for [HabitType]. Localized display names and default
/// unit labels live in the widget layer (they need [AppLocalizations]); this
/// file only holds Flutter-agnostic-ish presentation constants (icon + order).
extension HabitTypeX on HabitType {
  /// Icon shown in the type picker and on habit cards.
  IconData get icon => switch (this) {
        HabitType.alcohol => Icons.local_bar_rounded,
        HabitType.nicotine => Icons.smoking_rooms_rounded,
        HabitType.cannabis => Icons.grass_rounded,
        HabitType.sugar => Icons.cake_rounded,
        HabitType.gaming => Icons.sports_esports_rounded,
        HabitType.porn => Icons.no_adult_content_rounded,
        HabitType.other => Icons.adjust_rounded,
      };

  /// Whether this type warrants the medical taper warning (abrupt cessation
  /// can be dangerous). Benzodiazepines are not a separate type yet, so this
  /// currently covers alcohol.
  bool get needsMedicalWarning => this == HabitType.alcohol;
}

/// Stable display order for the type picker.
const List<HabitType> kHabitTypeOrder = <HabitType>[
  HabitType.alcohol,
  HabitType.nicotine,
  HabitType.cannabis,
  HabitType.sugar,
  HabitType.gaming,
  HabitType.porn,
  HabitType.other,
];
