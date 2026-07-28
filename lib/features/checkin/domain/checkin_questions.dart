/// The daily check-in ("Abfragen") questionnaire, defined as data.
///
/// Kept pure (no Flutter/drift) and configurable in one place so the question
/// set can grow without touching UI code. Each question has a stable [id] that
/// is the key both in the persisted `answersJson` and in the l10n lookup
/// (`checkin_l10n.dart`), so renaming a label never orphans stored answers.
library;

/// How a question is answered.
///
/// The spec lists `scale1to5`; we model scale generically with [Question.scaleMax]
/// so the "urge strength (1–10)" question fits the same type instead of needing
/// a parallel one.
enum QuestionType { scale, yesNo, multiSelect, freeText }

/// A single check-in question.
class Question {
  const Question({
    required this.id,
    required this.type,
    this.scaleMax = 5,
    this.optionKeys = const <String>[],
    this.optional = false,
  });

  /// Stable key — persisted in `answersJson` and used for l10n lookups.
  final String id;
  final QuestionType type;

  /// Upper bound for [QuestionType.scale] (lower bound is always 1).
  final int scaleMax;

  /// Option keys for [QuestionType.multiSelect]; each is an l10n key.
  final List<String> optionKeys;

  /// Optional questions never nag if left blank.
  final bool optional;
}

/// Ids referenced from special-case logic (e.g. "clean today? no → relapse").
class QuestionIds {
  const QuestionIds._();
  static const String cleanToday = 'cleanToday';
  static const String urgeStrength = 'urgeStrength';
  static const String helped = 'helped';
  static const String trigger = 'trigger';
  static const String triggerNote = 'triggerNote';
  static const String futureSelf = 'futureSelf';
}

/// The standard daily set. Order is the order shown. Designed to take under a
/// minute; the last two are optional so a missed sentence never feels like debt.
const List<Question> standardCheckin = <Question>[
  Question(id: QuestionIds.cleanToday, type: QuestionType.yesNo),
  Question(
    id: QuestionIds.urgeStrength,
    type: QuestionType.scale,
    scaleMax: 10,
  ),
  Question(
    id: QuestionIds.helped,
    type: QuestionType.multiSelect,
    optionKeys: <String>[
      'sport',
      'friends',
      'work',
      'sleep',
      'breathing',
      'nature',
      'music',
    ],
    optional: true,
  ),
  Question(
    id: QuestionIds.trigger,
    type: QuestionType.multiSelect,
    optionKeys: <String>[
      'stress',
      'boredom',
      'social',
      'emotions',
      'habit',
      'celebration',
    ],
    optional: true,
  ),
  Question(
    id: QuestionIds.triggerNote,
    type: QuestionType.freeText,
    optional: true,
  ),
  Question(
    id: QuestionIds.futureSelf,
    type: QuestionType.freeText,
    optional: true,
  ),
];
