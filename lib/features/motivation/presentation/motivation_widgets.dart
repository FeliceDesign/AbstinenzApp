import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/database.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/color_field_card.dart';
import '../../../l10n/app_localizations.dart';
import 'motivation_providers.dart';

/// Dashboard "your why" quote of the day (a pinned why, stable within a day).
class DashboardWhyCard extends ConsumerWidget {
  const DashboardWhyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final Motivation? why = ref.watch(dailyWhyProvider);

    // Light gold/cream colour field with dark ink text — the mockup's
    // `.card-why`. A light field (rather than a saturated one) makes the berry
    // urge FAB that floats over this card stand out sharply.
    const Color ink = AppColors.lightTextPrimary;
    const Color labelColor = AppColors.brandBerry;
    return ColorFieldCard(
      fill: AppColors.brandGold,
      onFill: ink,
      onTap: () => context.push('/motivation'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.format_quote_rounded,
                size: 20,
                color: labelColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.dashWhyTitle,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: labelColor,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            why?.content ?? l10n.dashWhyEmpty,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: ink,
              fontStyle: why == null ? FontStyle.italic : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Recalls the user's motivations inside the relapse and urge flows.
///
/// This is the Phase-4 integration point required by the plan: the person's
/// own words appear exactly when they're wavering.
class MotivationRecall extends ConsumerWidget {
  const MotivationRecall({
    this.showWhy = true,
    this.showBenefits = false,
    this.showConsequences = false,
    super.key,
  });

  final bool showWhy;
  final bool showBenefits;
  final bool showConsequences;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final whys = showWhy
        ? ref
                .watch(motivationsByKindProvider(MotivationKind.why))
                .valueOrNull ??
            const []
        : const <Motivation>[];
    final consequences = showConsequences
        ? ref
                .watch(motivationsByKindProvider(MotivationKind.consequence))
                .valueOrNull ??
            const []
        : const <Motivation>[];
    final benefits = showBenefits
        ? ref
                .watch(motivationsByKindProvider(MotivationKind.benefit))
                .valueOrNull ??
            const []
        : const <Motivation>[];

    final sections = <Widget>[
      if (whys.isNotEmpty) _Section(title: l10n.tabWhy, items: whys),
      if (consequences.isNotEmpty)
        _Section(title: l10n.tabConsequences, items: consequences),
      if (benefits.isNotEmpty)
        _Section(title: l10n.tabBenefits, items: benefits),
    ];

    if (sections.isEmpty) {
      return Text(
        l10n.motRecallEmpty,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});
  final String title;
  final List<Motivation> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          for (final m in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: theme.textTheme.bodyLarge),
                  Expanded(
                    child: Text(m.content, style: theme.textTheme.bodyLarge),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
