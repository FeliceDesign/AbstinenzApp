import '../../../core/db/database.dart';
import '../../../l10n/app_localizations.dart';

/// Resolves a milestone to its display title. Custom milestones store their text
/// in `key`, so it is used verbatim; time milestones use the duration label;
/// health milestones use their (localized) physiological note.
String milestoneTitle(AppLocalizations l10n, Milestone m) {
  if (m.isCustom) return m.key;
  return switch (m.key) {
    't_1h' => l10n.ms1h,
    't_12h' => l10n.ms12h,
    't_24h' => l10n.ms24h,
    't_3d' => l10n.ms3d,
    't_1w' => l10n.ms1w,
    't_2w' => l10n.ms2w,
    't_1m' => l10n.ms1m,
    't_3m' => l10n.ms3m,
    't_6m' => l10n.ms6m,
    't_1y' => l10n.ms1y,
    't_2y' => l10n.ms2y,
    't_5y' => l10n.ms5y,
    'nic_20m' => l10n.msNic20m,
    'nic_12h' => l10n.msNic12h,
    'nic_2w' => l10n.msNic2w,
    'nic_1m' => l10n.msNic1m,
    'nic_1y' => l10n.msNic1y,
    'alc_24h' => l10n.msAlc24h,
    'alc_1w' => l10n.msAlc1w,
    'alc_1m' => l10n.msAlc1m,
    'alc_3m' => l10n.msAlc3m,
    'can_1d' => l10n.msCan1d,
    'can_1w' => l10n.msCan1w,
    'can_1m' => l10n.msCan1m,
    'sug_3d' => l10n.msSug3d,
    'sug_1w' => l10n.msSug1w,
    'sug_1m' => l10n.msSug1m,
    _ => m.key,
  };
}

/// A compact, language-neutral duration label for a milestone's threshold chip
/// (e.g. "20 min", "12 h", "3 d", "2 w", "6 mo", "1 y").
String shortDuration(int seconds) {
  if (seconds < 3600) return '${seconds ~/ 60} min';
  if (seconds < 86400) return '${seconds ~/ 3600} h';
  final int days = seconds ~/ 86400;
  if (days < 7) return '$days d';
  if (days < 30) return '${days ~/ 7} w';
  if (days < 365) return '${days ~/ 30} mo';
  return '${(days / 365).round()} y';
}
