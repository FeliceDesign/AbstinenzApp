import '../../../core/db/database.dart';

/// Milestone catalogue: the time-based set (shared by every habit) plus
/// health milestones per habit type. Each entry is a stable [key] that is what
/// gets persisted in the `Milestones` table and looked up for its localized
/// title/body in the presentation layer (`milestone_l10n.dart`).
///
/// Health-milestone timings are rough, widely-published figures, cited in the
/// comments beside each. They are encouragement, not medical claims — the UI
/// wording stays non-clinical.
///
/// Pure: imports the drift [HabitType] enum only (like `benefit_presets.dart`),
/// no Flutter.

class MilestoneDef {
  const MilestoneDef({
    required this.key,
    required this.threshold,
    this.isHealth = false,
  });

  /// Stable identifier, persisted and used for the l10n lookup.
  final String key;

  /// Clean time after which the milestone is reached.
  final Duration threshold;

  /// Health milestones get a distinct icon/section; time milestones don't.
  final bool isHealth;

  int get thresholdSeconds => threshold.inSeconds;
}

/// The shared time ladder: 1h … 5y.
const List<MilestoneDef> timeMilestones = <MilestoneDef>[
  MilestoneDef(key: 't_1h', threshold: Duration(hours: 1)),
  MilestoneDef(key: 't_12h', threshold: Duration(hours: 12)),
  MilestoneDef(key: 't_24h', threshold: Duration(days: 1)),
  MilestoneDef(key: 't_3d', threshold: Duration(days: 3)),
  MilestoneDef(key: 't_1w', threshold: Duration(days: 7)),
  MilestoneDef(key: 't_2w', threshold: Duration(days: 14)),
  MilestoneDef(key: 't_1m', threshold: Duration(days: 30)),
  MilestoneDef(key: 't_3m', threshold: Duration(days: 90)),
  MilestoneDef(key: 't_6m', threshold: Duration(days: 180)),
  MilestoneDef(key: 't_1y', threshold: Duration(days: 365)),
  MilestoneDef(key: 't_2y', threshold: Duration(days: 730)),
  MilestoneDef(key: 't_5y', threshold: Duration(days: 1825)),
];

/// Health milestones per habit type (empty for types where a physiological
/// timeline isn't meaningful — those still get the time ladder + custom ones).
List<MilestoneDef> healthMilestones(HabitType type) => switch (type) {
      // Sources: US CDC "Within 20 minutes of quitting", NHS smoking timeline.
      HabitType.nicotine => const <MilestoneDef>[
          MilestoneDef(
            key: 'nic_20m',
            threshold: Duration(minutes: 20),
            isHealth: true,
          ), // heart rate & blood pressure begin to normalize
          MilestoneDef(
            key: 'nic_12h',
            threshold: Duration(hours: 12),
            isHealth: true,
          ), // blood carbon-monoxide drops to normal
          MilestoneDef(
            key: 'nic_2w',
            threshold: Duration(days: 14),
            isHealth: true,
          ), // circulation & lung function start improving
          MilestoneDef(
            key: 'nic_1m',
            threshold: Duration(days: 30),
            isHealth: true,
          ), // cilia recover, less coughing
          MilestoneDef(
            key: 'nic_1y',
            threshold: Duration(days: 365),
            isHealth: true,
          ), // excess heart-disease risk about halved
        ],
      // Sources: NHS / UK CMO alcohol guidance, general hepatology.
      HabitType.alcohol => const <MilestoneDef>[
          MilestoneDef(
            key: 'alc_24h',
            threshold: Duration(days: 1),
            isHealth: true,
          ), // sleep onset & blood sugar begin to settle
          MilestoneDef(
            key: 'alc_1w',
            threshold: Duration(days: 7),
            isHealth: true,
          ), // hydration & skin improve, liver starts recovering
          MilestoneDef(
            key: 'alc_1m',
            threshold: Duration(days: 30),
            isHealth: true,
          ), // liver fat reduced, sharper concentration
          MilestoneDef(
            key: 'alc_3m',
            threshold: Duration(days: 90),
            isHealth: true,
          ), // liver function markedly improved
        ],
      HabitType.cannabis => const <MilestoneDef>[
          MilestoneDef(
            key: 'can_1d',
            threshold: Duration(days: 1),
            isHealth: true,
          ), // REM sleep begins to return
          MilestoneDef(
            key: 'can_1w',
            threshold: Duration(days: 7),
            isHealth: true,
          ), // clearer thinking, short-term memory improves
          MilestoneDef(
            key: 'can_1m',
            threshold: Duration(days: 30),
            isHealth: true,
          ), // lung irritation eases (if it was smoked)
        ],
      HabitType.sugar => const <MilestoneDef>[
          MilestoneDef(
            key: 'sug_3d',
            threshold: Duration(days: 3),
            isHealth: true,
          ), // taste sensitivity increases
          MilestoneDef(
            key: 'sug_1w',
            threshold: Duration(days: 7),
            isHealth: true,
          ), // steadier energy, fewer cravings
          MilestoneDef(
            key: 'sug_1m',
            threshold: Duration(days: 30),
            isHealth: true,
          ), // steadier mood, clearer skin
        ],
      HabitType.gaming || HabitType.porn || HabitType.other =>
        const <MilestoneDef>[],
    };

/// The full preset set seeded for a habit of [type]: time ladder + health set,
/// sorted by threshold.
List<MilestoneDef> presetMilestones(HabitType type) {
  final List<MilestoneDef> all = <MilestoneDef>[
    ...timeMilestones,
    ...healthMilestones(type),
  ]..sort((MilestoneDef a, MilestoneDef b) =>
      a.thresholdSeconds.compareTo(b.thresholdSeconds));
  return all;
}
