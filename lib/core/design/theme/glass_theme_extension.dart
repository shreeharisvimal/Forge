// Glass theme extension for the Forge Design System.
//
// Centralizes every glassmorphism parameter — fill, border, blur, radius,
// elevation and glow — through [ThemeData.extensions]. The glass decorators
// and widgets resolve their defaults from this extension.
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../colors/forge_colors.dart';
import '../colors/forge_light_colors.dart';
import '../tokens/blur_tokens.dart';
import '../tokens/border_width_tokens.dart';
import '../tokens/elevation_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/shadow_presets.dart';

/// Glass parameters available to every Forge widget.
class GlassThemeExtension extends ThemeExtension<GlassThemeExtension> {
  /// Creates a glass theme extension.
  const GlassThemeExtension({
    required this.glassColor,
    required this.glassStrongColor,
    required this.borderColor,
    required this.borderStrongColor,
    required this.highlightColor,
    required this.glowColor,
    required this.blur,
    required this.borderRadius,
    required this.borderWidth,
    required this.elevation,
    required this.shadows,
  });

  /// Creates the default fallback glass extension.
  factory GlassThemeExtension.fallback() {
    return const GlassThemeExtension(
      glassColor: ForgeColors.glass,
      glassStrongColor: ForgeColors.glassStrong,
      borderColor: ForgeColors.border,
      borderStrongColor: ForgeColors.borderStrong,
      highlightColor: Color(0x0AFFFFFF),
      glowColor: ForgeColors.primary,
      blur: AppBlur.light,
      borderRadius: AppRadius.large,
      borderWidth: AppBorderWidth.thin,
      elevation: AppElevation.raised,
      shadows: AppShadows.raised,
    );
  }

  /// Creates the light-mode glass extension.
  factory GlassThemeExtension.lightFallback() {
    return const GlassThemeExtension(
      glassColor: ForgeLightColors.glass,
      glassStrongColor: ForgeLightColors.glassStrong,
      borderColor: ForgeLightColors.border,
      borderStrongColor: ForgeLightColors.borderStrong,
      highlightColor: Color(0x0AFFFFFF),
      glowColor: ForgeColors.primary,
      blur: AppBlur.light,
      borderRadius: AppRadius.large,
      borderWidth: AppBorderWidth.thin,
      elevation: AppElevation.raised,
      shadows: AppShadows.raised,
    );
  }

  /// Default glass fill color (6% white).
  final Color glassColor;

  /// Strong glass fill color (9% white).
  final Color glassStrongColor;

  /// Default glass border color (8% white).
  final Color borderColor;

  /// Strong glass border color (12% white).
  final Color borderStrongColor;

  /// Soft inner highlight color.
  final Color highlightColor;

  /// Ambient glow color used for emphasis.
  final Color glowColor;

  /// Default backdrop blur sigma.
  final double blur;

  /// Default corner radius.
  final double borderRadius;

  /// Default border width.
  final double borderWidth;

  /// Default elevation.
  final double elevation;

  /// Default layered shadow presets.
  final List<BoxShadow> shadows;

  @override
  GlassThemeExtension copyWith({
    Color? glassColor,
    Color? glassStrongColor,
    Color? borderColor,
    Color? borderStrongColor,
    Color? highlightColor,
    Color? glowColor,
    double? blur,
    double? borderRadius,
    double? borderWidth,
    double? elevation,
    List<BoxShadow>? shadows,
  }) {
    return GlassThemeExtension(
      glassColor: glassColor ?? this.glassColor,
      glassStrongColor: glassStrongColor ?? this.glassStrongColor,
      borderColor: borderColor ?? this.borderColor,
      borderStrongColor: borderStrongColor ?? this.borderStrongColor,
      highlightColor: highlightColor ?? this.highlightColor,
      glowColor: glowColor ?? this.glowColor,
      blur: blur ?? this.blur,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      elevation: elevation ?? this.elevation,
      shadows: shadows ?? this.shadows,
    );
  }

  @override
  GlassThemeExtension lerp(
      ThemeExtension<GlassThemeExtension>? other, double t) {
    if (other is! GlassThemeExtension) return this;
    return GlassThemeExtension(
      glassColor: Color.lerp(glassColor, other.glassColor, t)!,
      glassStrongColor:
          Color.lerp(glassStrongColor, other.glassStrongColor, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      borderStrongColor:
          Color.lerp(borderStrongColor, other.borderStrongColor, t)!,
      highlightColor: Color.lerp(highlightColor, other.highlightColor, t)!,
      glowColor: Color.lerp(glowColor, other.glowColor, t)!,
      blur: lerpDouble(blur, other.blur, t)!,
      borderRadius: lerpDouble(borderRadius, other.borderRadius, t)!,
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t)!,
      elevation: lerpDouble(elevation, other.elevation, t)!,
      shadows: t < 0.5 ? shadows : other.shadows,
    );
  }
}
