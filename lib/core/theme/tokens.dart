import 'package:flutter/widgets.dart';

/// Central design tokens for the app.
///
/// Rationale: the client is a media designer and explicitly does not want the
/// Material default look. Every colour, radius and spacing value lives here so
/// widgets never contain colour literals or magic numbers. This is the single
/// source of truth for the brand.
///
/// WCAG AA contrast notes (verified against the neutrals below):
///  - textPrimary (#EAF2F8) on bgSurfaceRaised (#1A232E) -> ~13.9:1 (AAA)
///  - textSecondary (#9DB0C0) on bgSurfaceRaised (#1A232E) -> ~6.8:1 (AA)
///  - dark text (#10171F) on brandGold (#F2D197) -> ~13.3:1 (AAA)
///  - dark text (#10171F) on brandSand (#E9BA90) -> ~11.6:1 (AAA)
///  - white (#EAF2F8) on brandBerry (#952D5D) -> ~6.4:1 (AA)
class AppColors {
  const AppColors._();

  // --- Brand palette (fixed, never altered) ---------------------------------
  /// Light surface, chart fills, onboarding illustration, light-mode tint.
  static const Color brandSkyLight = Color(0xFFBCE1F6);

  /// Primary. Interactive elements, links, focus rings, active nav items.
  static const Color brandSky = Color(0xFF8CC6F2);

  /// Darkened primary for light mode (brandSky is too light for text there).
  /// Derived from brandSky keeping hue, per design directive.
  static const Color brandSkyOnLight = Color(0xFF2B7FBF);

  /// Success / progress. Streak ticker, milestone rings, achieved goals.
  static const Color brandGold = Color(0xFFF2D197);

  /// Secondary warm. Gradient partner to gold, mood scale top, saving goals.
  static const Color brandSand = Color(0xFFE9BA90);

  /// Signal colour, exclusively for the urge button and its flow.
  static const Color brandBerry = Color(0xFF952D5D);

  /// Technical error/validation only (desaturated berry). Never for behaviour.
  static const Color error = Color(0xFFC4576F);

  // --- Dark neutrals (default theme) ----------------------------------------
  static const Color darkBgBase = Color(0xFF0A0E13);
  static const Color darkBgSurface = Color(0xFF121922);
  static const Color darkBgSurfaceRaised = Color(0xFF1A232E);
  static const Color darkBgSurfaceHigh = Color(0xFF232F3C);
  static const Color darkOutline = Color(0xFF2E3B49);
  static const Color darkOutlineSubtle = Color(0xFF1F2933);
  static const Color darkTextPrimary = Color(0xFFEAF2F8);
  static const Color darkTextSecondary = Color(0xFF9DB0C0);
  static const Color darkTextTertiary = Color(0xFF67788A);

  // --- Light neutrals -------------------------------------------------------
  static const Color lightBgBase = Color(0xFFF6FAFD);
  static const Color lightBgSurface = Color(0xFFFFFFFF);
  static const Color lightBgSurfaceRaised = Color(0xFFEFF6FB);
  static const Color lightBgSurfaceHigh = Color(0xFFE4EEF6);
  static const Color lightOutline = Color(0xFFD3E1EC);
  static const Color lightOutlineSubtle = Color(0xFFE1EBF3);
  static const Color lightTextPrimary = Color(0xFF10171F);
  static const Color lightTextSecondary = Color(0xFF4A5C6D);
  static const Color lightTextTertiary = Color(0xFF7C8B9A);

  /// Scrim used for modal overlays (72% of bgBase).
  static Color darkScrim = const Color(0xFF0A0E13).withValues(alpha: 0.72);
  static Color lightScrim = const Color(0xFF10171F).withValues(alpha: 0.45);

  // --- Mood ramp (1..5). Ordinal, cool-muted -> warm-bright. Never colour ---
  // alone: always paired with a face icon (see mood feature / A11y rule).
  static const List<Color> mood = <Color>[
    Color(0xFF4A5566), // 1
    Color(0xFF6E7B85), // 2
    Color(0xFFA9968A), // 3
    Color(0xFFE9BA90), // 4 (brandSand)
    Color(0xFFF2D197), // 5 (brandGold)
  ];
}

/// Spacing scale, strict 4px base.
class AppSpacing {
  const AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;
}

/// Corner radius scale. Generous rounding carries the "inviting" requirement.
class AppRadius {
  const AppRadius._();
  static const double sm = 12;
  static const double md = 20;
  static const double lg = 28;
  static const double pill = 999;

  static const Radius smR = Radius.circular(sm);
  static const Radius mdR = Radius.circular(md);
  static const Radius lgR = Radius.circular(lg);
}

/// Motion durations and curves.
class AppMotion {
  const AppMotion._();
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 900);
  static const Curve standard = Curves.easeOutCubic;
  static const Curve breathe = Curves.easeInOutSine;
}

/// Font families (bundled locally, no network fetch — see assets/fonts).
class AppFonts {
  const AppFonts._();

  /// Display / numeric. Use with tabular figures for the ticker.
  static const String display = 'SpaceGrotesk';

  /// Body / UI.
  static const String body = 'Inter';

  /// Tabular figures feature — mandatory for any live-updating number so the
  /// layout does not jump every second.
  static const List<FontFeature> tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];
}
