// Typography for the Forge Design System.
//
// Builds the complete Material 3 [TextTheme] on the Inter typeface with a
// modern hierarchy: large display titles, readable body and tabular
// numerals for premium number styling.
library;

import 'package:flutter/material.dart';

/// Central typography definitions for Forge.
///
/// Exposes the full [TextTheme] used by the design system plus named
/// role getters so widgets can request a style by intent.
abstract final class ForgeTypography {
  ForgeTypography._();

  /// Display font used for headlines.
  static const String displayFont = 'Inter';

  /// Body font used for readable text.
  static const String bodyFont = 'Inter';

  /// Builds the application [TextTheme].
  ///
  /// Named type scale on the Inter typeface, mapped onto the Material roles:
  ///
  /// | Role         | Material slot      | Size |
  /// |--------------|--------------------|------|
  /// | Display      | displayLarge/Med/S | 32/28/24 |
  /// | Headline     | headlineLarge/Med  | 24/20/18 |
  /// | Title        | titleLarge/Med/Sm  | 20/17/15 |
  /// | Subtitle     | titleSmall         | 15 |
  /// | Body         | bodyLarge/Medium   | 15/13 |
  /// | Body Small   | bodySmall          | 11 |
  /// | Caption      | labelSmall         | 11 |
  /// | Button       | labelLarge/Medium  | 15/13 |
  /// | Overline     | [overlineStyle]    | 11 |
  ///
  /// Display and headline roles use heavier weights with tight letter
  /// spacing; body roles favour readability. The theme is tinted for the
  /// [brightness] (the dark AMOLED background, or the light surface).
  static TextTheme textTheme({Brightness brightness = Brightness.dark}) {
    final base = Typography.material2021().black;

    final themed = base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: displayFont,
        fontSize: 32,
        height: 1.1,
        letterSpacing: -0.6,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontFamily: displayFont,
        fontSize: 28,
        height: 1.15,
        letterSpacing: -0.5,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontFamily: displayFont,
        fontSize: 24,
        height: 1.2,
        letterSpacing: -0.4,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontFamily: displayFont,
        fontSize: 24,
        height: 1.2,
        letterSpacing: -0.4,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: displayFont,
        fontSize: 20,
        height: 1.25,
        letterSpacing: -0.3,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontFamily: displayFont,
        fontSize: 18,
        height: 1.3,
        letterSpacing: -0.2,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: displayFont,
        fontSize: 20,
        height: 1.25,
        letterSpacing: -0.3,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: displayFont,
        fontSize: 17,
        height: 1.3,
        letterSpacing: -0.2,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontFamily: displayFont,
        fontSize: 15,
        height: 1.35,
        letterSpacing: -0.1,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: bodyFont,
        fontSize: 15,
        height: 1.45,
        letterSpacing: 0,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: bodyFont,
        fontSize: 13,
        height: 1.4,
        letterSpacing: 0.1,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontFamily: bodyFont,
        fontSize: 11,
        height: 1.35,
        letterSpacing: 0.2,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontFamily: bodyFont,
        fontSize: 15,
        height: 1.35,
        letterSpacing: 0,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontFamily: bodyFont,
        fontSize: 13,
        height: 1.3,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontFamily: bodyFont,
        fontSize: 11,
        height: 1.3,
        letterSpacing: 0.2,
        fontWeight: FontWeight.w600,
      ),
    );

    // Apply the theme tint. Inter is bundled with the app via the pubspec
    // `fonts` section, so no runtime font fetching is required.
    final onSurface = brightness == Brightness.light
        ? const Color(0xFF17171F)
        : const Color(0xFFF5F5F7);
    return themed.apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );
  }

  /// An eyebrow / overline style for uppercase micro-labels (section
  /// headers, meta labels, chip captions).
  static TextStyle overlineStyle({
    Color? color,
  }) {
    return TextStyle(
      fontFamily: bodyFont,
      fontSize: 11,
      height: 1.3,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  /// A tabular-numeral style for displaying metrics and counts.
  static TextStyle numberStyle({
    double fontSize = 28,
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: bodyFont,
      fontSize: fontSize,
      fontWeight: weight,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: color,
    );
  }
}
