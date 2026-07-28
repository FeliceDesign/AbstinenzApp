import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/calorie_equivalents.dart';

/// Formats [amount] as currency (e.g. "12.34 €") for [currency] in [locale].
String formatMoney(String locale, String currency, double amount) {
  return NumberFormat.simpleCurrency(locale: locale, name: currency)
      .format(amount);
}

/// Formats calories as a rounded integer with a thousands separator.
String formatKcal(String locale, double kcal) =>
    NumberFormat.decimalPattern(locale).format(kcal.round());

/// Localized "≈ N pizzas / km / bars" label for a calorie equivalent.
String calorieEquivalentLabel(AppLocalizations l10n, CalorieEquivalent e) =>
    switch (e.kind) {
      EquivalentKind.pizza => l10n.calEquivPizza(e.amount),
      EquivalentKind.running => l10n.calEquivRunning(e.amount),
      EquivalentKind.chocolate => l10n.calEquivChocolate(e.amount),
    };
