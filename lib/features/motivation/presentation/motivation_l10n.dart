import '../../../l10n/app_localizations.dart';

/// Resolves a benefit-preset key to localized text.
String benefitPresetLabel(AppLocalizations l10n, String key) => switch (key) {
      'benGenClearHead' => l10n.benGenClearHead,
      'benGenMoney' => l10n.benGenMoney,
      'benGenSleep' => l10n.benGenSleep,
      'benGenPride' => l10n.benGenPride,
      'benNicBreath' => l10n.benNicBreath,
      'benNicTaste' => l10n.benNicTaste,
      'benNicSkin' => l10n.benNicSkin,
      'benAlcSleep' => l10n.benAlcSleep,
      'benAlcLiver' => l10n.benAlcLiver,
      'benAlcMood' => l10n.benAlcMood,
      'benCanFocus' => l10n.benCanFocus,
      'benCanMotivation' => l10n.benCanMotivation,
      'benSugEnergy' => l10n.benSugEnergy,
      'benSugTeeth' => l10n.benSugTeeth,
      'benGamTime' => l10n.benGamTime,
      'benGamPosture' => l10n.benGamPosture,
      'benPornPresence' => l10n.benPornPresence,
      'benPornConnection' => l10n.benPornConnection,
      _ => key,
    };
