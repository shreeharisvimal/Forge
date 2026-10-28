// Typography theme extension for the Forge Design System.
//
// Exposes the full [TextTheme] through [ThemeData.extensions] so widgets
// can read the shared type scale without rebuilding it.
library;

import 'package:flutter/material.dart';

import '../typography/forge_typography.dart';

/// Typography tokens available to every Forge widget.
class TypographyThemeExtension extends ThemeExtension<TypographyThemeExtension> {
  /// Creates a typography theme extension.
  const TypographyThemeExtension({required this.textTheme});

  /// Creates the default fallback typography extension.
  factory TypographyThemeExtension.fallback() {
    return TypographyThemeExtension(textTheme: ForgeTypography.textTheme());
  }

  /// The shared [TextTheme] for the design system.
  final TextTheme textTheme;

  @override
  TypographyThemeExtension copyWith({TextTheme? textTheme}) {
    return TypographyThemeExtension(textTheme: textTheme ?? this.textTheme);
  }

  @override
  TypographyThemeExtension lerp(
      ThemeExtension<TypographyThemeExtension>? other, double t) {
    if (other is! TypographyThemeExtension) return this;
    return TypographyThemeExtension(
      textTheme: TextTheme.lerp(textTheme, other.textTheme, t),
    );
  }
}