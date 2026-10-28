// Spacing theme extension for the Forge Design System.
//
// Exposes the spacing scale through [ThemeData.extensions] so widgets can
// resolve responsive spacing without importing the token class directly.
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../tokens/spacing_tokens.dart';

/// Layout spacing tokens available to every Forge widget.
class SpacingThemeExtension extends ThemeExtension<SpacingThemeExtension> {
  /// Creates a spacing theme extension.
  const SpacingThemeExtension({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.xxxl,
    required this.huge,
    required this.giant,
  });

  /// Creates the default fallback spacing extension.
  factory SpacingThemeExtension.fallback() {
    return const SpacingThemeExtension(
      xs: AppSpacing.xs,
      sm: AppSpacing.sm,
      md: AppSpacing.md,
      lg: AppSpacing.lg,
      xl: AppSpacing.xl,
      xxl: AppSpacing.xxl,
      xxxl: AppSpacing.xxxl,
      huge: AppSpacing.huge,
      giant: AppSpacing.giant,
    );
  }

  /// 4 dp.
  final double xs;

  /// 8 dp.
  final double sm;

  /// 12 dp.
  final double md;

  /// 16 dp.
  final double lg;

  /// 20 dp.
  final double xl;

  /// 24 dp.
  final double xxl;

  /// 32 dp.
  final double xxxl;

  /// 40 dp.
  final double huge;

  /// 48 dp.
  final double giant;

  /// A four-sided [EdgeInsets] using this scale's values.
  EdgeInsets all(double value) => EdgeInsets.all(value);

  /// A symmetric [EdgeInsets] using this scale's values.
  EdgeInsets symmetric({double? horizontal, double? vertical}) {
    return EdgeInsets.symmetric(
      horizontal: horizontal ?? 0,
      vertical: vertical ?? 0,
    );
  }

  @override
  SpacingThemeExtension copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? xxxl,
    double? huge,
    double? giant,
  }) {
    return SpacingThemeExtension(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      xxxl: xxxl ?? this.xxxl,
      huge: huge ?? this.huge,
      giant: giant ?? this.giant,
    );
  }

  @override
  SpacingThemeExtension lerp(
      ThemeExtension<SpacingThemeExtension>? other, double t) {
    if (other is! SpacingThemeExtension) return this;
    return SpacingThemeExtension(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      xxl: lerpDouble(xxl, other.xxl, t)!,
      xxxl: lerpDouble(xxxl, other.xxxl, t)!,
      huge: lerpDouble(huge, other.huge, t)!,
      giant: lerpDouble(giant, other.giant, t)!,
    );
  }
}
