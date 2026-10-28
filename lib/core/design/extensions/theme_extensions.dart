// Theme accessors for the Forge Design System.
//
// Exposes every Forge theme extension as a typed getter on [ThemeData] so
// widgets read tokens ergonomically with a guaranteed fallback.
library;

import 'package:flutter/material.dart';

import '../theme/animation_theme_extension.dart';
import '../theme/color_theme_extension.dart';
import '../theme/glass_theme_extension.dart';
import '../theme/spacing_theme_extension.dart';
import '../theme/typography_theme_extension.dart';

/// Typed accessors for Forge theme extensions on [ThemeData].
extension ForgeThemeX on ThemeData {
  /// The glass parameters for the current theme.
  GlassThemeExtension get glass =>
      extension<GlassThemeExtension>() ?? GlassThemeExtension.fallback();

  /// The semantic color palette for the current theme.
  ColorThemeExtension get forgeColors =>
      extension<ColorThemeExtension>() ?? ColorThemeExtension.fallback();

  /// The spacing scale for the current theme.
  SpacingThemeExtension get spacing =>
      extension<SpacingThemeExtension>() ?? SpacingThemeExtension.fallback();

  /// The animation durations and curves for the current theme.
  AnimationThemeExtension get anim =>
      extension<AnimationThemeExtension>() ?? AnimationThemeExtension.fallback();

  /// The shared typography for the current theme.
  TypographyThemeExtension get forgeTypography =>
      extension<TypographyThemeExtension>() ??
      TypographyThemeExtension.fallback();
}
