import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the app's [ThemeData] for light and dark.
///
/// Rationale: `useMaterial3: true` is on, but the [ColorScheme] is defined by
/// hand rather than via `ColorScheme.fromSeed`. Seed generation would tonally
/// shift our fixed brand hexes and break the exact palette the designer
/// specified, so we map each role explicitly. Trade-off: more verbose and we
/// lose Material's automatic tonal harmony, but colour fidelity wins here.
class AppTheme {
  const AppTheme._();

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        bgBase: AppColors.darkBgBase,
        surface: AppColors.darkBgSurface,
        surfaceRaised: AppColors.darkBgSurfaceRaised,
        surfaceHigh: AppColors.darkBgSurfaceHigh,
        outline: AppColors.darkOutline,
        outlineSubtle: AppColors.darkOutlineSubtle,
        textPrimary: AppColors.darkTextPrimary,
        textSecondary: AppColors.darkTextSecondary,
        primary: AppColors.brandSky,
        onPrimary: AppColors.darkBgBase,
        scrim: AppColors.darkScrim,
      );

  static ThemeData light() => _build(
        brightness: Brightness.light,
        bgBase: AppColors.lightBgBase,
        surface: AppColors.lightBgSurface,
        surfaceRaised: AppColors.lightBgSurfaceRaised,
        surfaceHigh: AppColors.lightBgSurfaceHigh,
        outline: AppColors.lightOutline,
        outlineSubtle: AppColors.lightOutlineSubtle,
        textPrimary: AppColors.lightTextPrimary,
        textSecondary: AppColors.lightTextSecondary,
        // brandSky is too light for text/icons on a light background, so the
        // interactive role uses the darkened variant there.
        primary: AppColors.brandSkyOnLight,
        onPrimary: Colors.white,
        scrim: AppColors.lightScrim,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bgBase,
    required Color surface,
    required Color surfaceRaised,
    required Color surfaceHigh,
    required Color outline,
    required Color outlineSubtle,
    required Color textPrimary,
    required Color textSecondary,
    required Color primary,
    required Color onPrimary,
    required Color scrim,
  }) {
    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: AppColors.brandSand,
      onSecondary: AppColors.lightTextPrimary,
      tertiary: AppColors.brandGold,
      onTertiary: AppColors.lightTextPrimary,
      error: AppColors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerLowest: bgBase,
      surfaceContainerLow: surface,
      surfaceContainer: surfaceRaised,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: surfaceHigh,
      onSurfaceVariant: textSecondary,
      outline: outline,
      outlineVariant: outlineSubtle,
      scrim: scrim,
    );

    final TextTheme textTheme = _textTheme(textPrimary, textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bgBase,
      canvasColor: bgBase,
      fontFamily: AppFonts.body,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: bgBase,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: outlineSubtle),
        ),
      ),
      dividerTheme: DividerThemeData(color: outlineSubtle, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.16),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? primary
                : textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? primary
                : textSecondary,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
    );
  }

  /// Type scale: display 56 / h1 32 / h2 24 / h3 20 / body 16 / bodySm 14 /
  /// caption 12. Line height 1.0 for display, 1.4 for running text.
  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 56,
        height: 1.0,
        fontWeight: FontWeight.w600,
        color: primary,
        fontFeatures: AppFonts.tabular,
      ),
      headlineLarge: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 32,
        height: 1.1,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        height: 1.0,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 1.0,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
    );
  }
}
