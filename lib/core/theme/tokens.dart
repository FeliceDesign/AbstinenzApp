import 'package:flutter/widgets.dart';

/// Central design tokens.
///
/// This is the "dawn-berry" system (see the style guide): **light-mode first**,
/// warm neutrals, and a swappable palette. Everything colourful is derived from
/// a single [_Palette] (the raw scale + warm neutrals); the [AppColors] members
/// below are the *semantic* names widgets use, so a palette swap only touches
/// [_Palette]. Interaction is the berry accent; achievement stays warm (gold →
/// sand); the urge flow keeps berry as its focused signal.
///
/// WCAG AA notes (light mode, the default):
///  - textPrimary (#332E2A) on bg (#F9F8F7) -> ~11.6:1 (AAA)
///  - textSecondary (#5E5650) on surface (#FFFFFF) -> ~7.0:1 (AA)
///  - white (#FFFFFF) on accent/berry (#952D5D) -> ~7.4:1 (AA)
///  - dark text (#332E2A) on gold (#F2D197) -> ~9.9:1 (AAA)
/// Dark mode:
///  - textPrimary (#F9F8F7) on bg (#0F0D0C) -> ~17:1 (AAA)
///  - dark text (#0F0D0C) on sky accent (#8CC6F2) -> ~9.7:1 (AAA)
class _Palette {
  const _Palette._();

  // Scale — 5 brand anchors (200/300/400/500/700) + interpolated ends.
  static const Color scale50 = Color(0xFFF7FBFD);
  static const Color scale100 = Color(0xFFE8F5FC);
  static const Color scale200 = Color(0xFFBCE1F6); // sky light
  static const Color scale300 = Color(0xFF8CC6F2); // sky
  static const Color scale400 = Color(0xFFF2D197); // gold
  static const Color scale500 = Color(0xFFE9BA90); // sand
  static const Color scale600 = Color(0xFFC77A6E); // warm rose
  static const Color scale700 = Color(0xFF952D5D); // berry
  static const Color scale800 = Color(0xFF6E2246);
  static const Color scale900 = Color(0xFF3D1329);

  // Warm neutrals (replace the old blue-tinted dark-first neutrals).
  static const Color n0 = Color(0xFFFFFFFF);
  static const Color n50 = Color(0xFFF9F8F7);
  static const Color n100 = Color(0xFFF0EEEC);
  static const Color n200 = Color(0xFFE2DEDA);
  static const Color n400 = Color(0xFF9C948C);
  static const Color n600 = Color(0xFF5E5650);
  static const Color n800 = Color(0xFF332E2A);
  static const Color n950 = Color(0xFF0F0D0C);
}

class AppColors {
  const AppColors._();

  // --- Brand palette (semantic aliases onto the scale) ----------------------
  /// Light sky — soft highlights, progress tracks, chart fills.
  static const Color brandSkyLight = _Palette.scale200;

  /// Sky — the dark-mode accent (interaction).
  static const Color brandSky = _Palette.scale300;

  /// Darkened sky for the rare "sky as text on a light surface" need.
  static const Color brandSkyOnLight = Color(0xFF2B7FBF);

  /// Gold — achievement / progress. Streak ticker, milestone rings.
  static const Color brandGold = _Palette.scale400;

  /// Sand — warm secondary, gradient partner to gold.
  static const Color brandSand = _Palette.scale500;

  /// Berry — the light-mode accent (primary actions) and the urge signal.
  static const Color brandBerry = _Palette.scale700;

  /// Semantic status colours, fixed independent of palette.
  static const Color success = Color(0xFF6FA97C);
  static const Color error = Color(0xFFC7554A);

  // --- Light neutrals (default theme) ---------------------------------------
  static const Color lightBgBase = _Palette.n50;
  static const Color lightBgSurface = _Palette.n0;
  static const Color lightBgSurfaceRaised = _Palette.n100;
  static const Color lightBgSurfaceHigh = _Palette.n200;
  static const Color lightOutline = _Palette.n200;
  static const Color lightOutlineSubtle = _Palette.n100;
  static const Color lightTextPrimary = _Palette.n800;
  static const Color lightTextSecondary = _Palette.n600;
  static const Color lightTextTertiary = _Palette.n400;

  // --- Dark neutrals (warm, full-featured option) ---------------------------
  static const Color darkBgBase = _Palette.n950;
  static const Color darkBgSurface = _Palette.n800;
  static const Color darkBgSurfaceRaised = Color(0xFF221E1B);
  static const Color darkBgSurfaceHigh = Color(0xFF2A2521);
  static const Color darkOutline = Color(0xFF3A342F);
  static const Color darkOutlineSubtle = Color(0xFF2A2521);
  static const Color darkTextPrimary = _Palette.n50;
  static const Color darkTextSecondary = _Palette.n400;
  static const Color darkTextTertiary = Color(0xFF7A716A);

  /// Scrims used for modal overlays.
  static Color darkScrim = _Palette.n950.withValues(alpha: 0.72);
  static Color lightScrim = _Palette.n800.withValues(alpha: 0.45);

  // --- Mood ramp (1..5). Ordinal, cool-muted -> warm-bright. Never colour ---
  // alone: always paired with a face icon (see mood feature / A11y rule).
  static const List<Color> mood = <Color>[
    Color(0xFF6E7B85), // 1 cool, muted
    Color(0xFF9AA0A0), // 2
    Color(0xFFC9B29E), // 3
    _Palette.scale500, // 4 (sand)
    _Palette.scale400, // 5 (gold)
  ];
}

/// Spacing scale, strict 4px base: 4/8/12/16/24/32/48/64.
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
///
/// The style guide favours "General Sans" for display; to keep the app fully
/// offline we stay with the already-bundled Space Grotesk, which shares the
/// same friendly-geometric character.
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
