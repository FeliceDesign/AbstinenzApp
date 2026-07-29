import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A card whose *surface is a colour field*, with text/icons inverted on top of
/// it — the core move of the "dawn-berry" system (see the style guide and the
/// reference dashboard mockup). This is deliberately **not** "a neutral card
/// with a coloured icon"; the whole card is the colour.
///
/// Used for the dashboard's hero (sky-gradient), milestone (sand) and "your
/// why" (berry) cards. Neutral cards keep using [Card]; on any one screen at
/// most about half the cards should stay neutral, the rest are colour fields.
class ColorFieldCard extends StatelessWidget {
  const ColorFieldCard({
    required this.child,
    this.fill,
    this.gradient,
    this.onFill = Colors.white,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.onTap,
    this.semanticLabel,
    super.key,
  }) : assert(
          fill != null || gradient != null,
          'Provide either a fill colour or a gradient.',
        );

  /// Solid fill (ignored when [gradient] is set).
  final Color? fill;

  /// Optional gradient fill for the hero card.
  final Gradient? gradient;

  /// The inverted content colour on top of the field — white on every field in
  /// the current palette (all fields clear WCAG AA against white).
  final Color onFill;

  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  final String? semanticLabel;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);

    final Widget content = Padding(padding: padding, child: child);

    // The colour field carries the content colour to every descendant, so
    // child widgets can rely on the ambient icon/text colour being inverted.
    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? fill : null,
        gradient: gradient,
        borderRadius: radius,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: IconTheme.merge(
            data: IconThemeData(color: onFill),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: onFill),
              child: ClipRRect(borderRadius: radius, child: content),
            ),
          ),
        ),
      ),
    );

    if (semanticLabel != null) {
      card = Semantics(
        container: true,
        label: semanticLabel,
        button: onTap != null,
        child: card,
      );
    }
    return card;
  }
}

/// A pill-shaped label/chip that reads on top of a colour field — the
/// translucent white pills in the mockup (habit tag, "Days only" toggle).
class FieldPill extends StatelessWidget {
  const FieldPill({
    required this.child,
    this.onFill = Colors.white,
    this.onTap,
    super.key,
  });

  final Widget child;
  final Color onFill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget body = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: onFill.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: onFill,
          fontFamily: AppFonts.body,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: onFill, size: 16),
          child: child,
        ),
      ),
    );
    if (onTap == null) return body;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: body,
      ),
    );
  }
}
