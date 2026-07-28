import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Presentation-layer lookups for mood: tag labels, face icons and the
/// accessibility label for each 1..5 score. Colour is never the only carrier of
/// meaning — every score always has a distinct face and a text label too.

/// Canonical mood-tag keys (labels resolved via [moodTagLabel]).
const List<String> moodTagKeys = <String>[
  'proud',
  'relaxed',
  'calm',
  'motivated',
  'irritable',
  'anxious',
  'lonely',
  'tired',
];

String moodTagLabel(AppLocalizations l10n, String key) => switch (key) {
      'proud' => l10n.moodTagProud,
      'relaxed' => l10n.moodTagRelaxed,
      'calm' => l10n.moodTagCalm,
      'motivated' => l10n.moodTagMotivated,
      'irritable' => l10n.moodTagIrritable,
      'anxious' => l10n.moodTagAnxious,
      'lonely' => l10n.moodTagLonely,
      'tired' => l10n.moodTagTired,
      _ => key,
    };

/// A distinct face per 1..5 score (never colour alone).
IconData moodFaceIcon(int score) => switch (score) {
      1 => Icons.sentiment_very_dissatisfied_rounded,
      2 => Icons.sentiment_dissatisfied_rounded,
      3 => Icons.sentiment_neutral_rounded,
      4 => Icons.sentiment_satisfied_rounded,
      _ => Icons.sentiment_very_satisfied_rounded,
    };

/// The ordinal mood colour for [score] (1..5), from the token ramp.
Color moodColor(int score) => AppColors.mood[(score - 1).clamp(0, 4).toInt()];

/// Accessibility / caption label for a mood score.
String moodScoreLabel(AppLocalizations l10n, int score) => switch (score) {
      1 => l10n.moodFace1,
      2 => l10n.moodFace2,
      3 => l10n.moodFace3,
      4 => l10n.moodFace4,
      _ => l10n.moodFace5,
    };
