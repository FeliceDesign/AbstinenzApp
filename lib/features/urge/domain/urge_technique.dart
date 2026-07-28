import 'package:flutter/material.dart';

/// The coping techniques offered in the urge toolkit. The enum `name` is the
/// stable key persisted in `UrgeEvents.techniqueUsed` and used for stats.
enum UrgeTechnique {
  urgeSurfing,
  breathing478,
  fifteenMinute,
  grounding54321,
  playTheTape,
  distraction,
  emergencyContact,
}

extension UrgeTechniqueX on UrgeTechnique {
  IconData get icon => switch (this) {
        UrgeTechnique.urgeSurfing => Icons.waves_rounded,
        UrgeTechnique.breathing478 => Icons.air_rounded,
        UrgeTechnique.fifteenMinute => Icons.hourglass_bottom_rounded,
        UrgeTechnique.grounding54321 => Icons.spa_rounded,
        UrgeTechnique.playTheTape => Icons.movie_outlined,
        UrgeTechnique.distraction => Icons.shuffle_rounded,
        UrgeTechnique.emergencyContact => Icons.call_rounded,
      };
}
