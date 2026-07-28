import '../../../l10n/app_localizations.dart';
import '../domain/checkin_questions.dart';

/// Resolves check-in question and option keys to localized labels. Keeping the
/// mapping out of the pure domain lets the question set stay Flutter-free.

String checkinQuestionLabel(AppLocalizations l10n, String id) => switch (id) {
      QuestionIds.cleanToday => l10n.qCleanToday,
      QuestionIds.urgeStrength => l10n.qUrgeStrength,
      QuestionIds.helped => l10n.qHelped,
      QuestionIds.trigger => l10n.qTrigger,
      QuestionIds.triggerNote => l10n.qTriggerNote,
      QuestionIds.futureSelf => l10n.qFutureSelf,
      _ => id,
    };

String checkinOptionLabel(AppLocalizations l10n, String key) => switch (key) {
      'sport' => l10n.optSport,
      'friends' => l10n.optFriends,
      'work' => l10n.optWork,
      'sleep' => l10n.optSleep,
      'breathing' => l10n.optBreathing,
      'nature' => l10n.optNature,
      'music' => l10n.optMusic,
      'stress' => l10n.trgStress,
      'boredom' => l10n.trgBoredom,
      'social' => l10n.trgSocial,
      'emotions' => l10n.trgEmotions,
      'habit' => l10n.trgHabit,
      'celebration' => l10n.trgCelebration,
      _ => key,
    };
