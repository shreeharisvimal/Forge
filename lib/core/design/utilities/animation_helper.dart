// Animation helper for the Forge Design System.
//
// Resolves durations and curves from the animation theme and provides a
// single place to build controllers and tweens so motion stays consistent.
library;

import 'package:flutter/material.dart';

import '../theme/animation_theme_extension.dart';
import '../tokens/curve_tokens.dart';
import '../tokens/duration_tokens.dart';

/// Helpers for creating consistent animations.
abstract final class AnimationHelper {
  AnimationHelper._();

  /// The animation theme extension for [context].
  static AnimationThemeExtension themeOf(BuildContext context) {
    return Theme.of(context).extension<AnimationThemeExtension>() ??
        AnimationThemeExtension.fallback();
  }

  /// Resolves the [duration] or falls back to the theme's medium duration.
  static Duration durationOf(
    BuildContext context, {
    Duration? duration,
  }) {
    return duration ?? themeOf(context).medium;
  }

  /// Resolves the [curve] or falls back to the theme's standard curve.
  static Curve curveOf(BuildContext context, {Curve? curve}) {
    return curve ?? themeOf(context).standard;
  }

  /// The theme's spring curve.
  static Curve springCurveOf(BuildContext context) => themeOf(context).spring;

  /// Builds a [CurvedAnimation] from the resolved curve.
  static CurvedAnimation curved(
    Animation<double> parent,
    BuildContext context, {
    Curve? curve,
  }) {
    return CurvedAnimation(parent: parent, curve: curveOf(context, curve: curve));
  }

  /// Builds a tween that snaps to [end] using the [AppCurves.spring] easing.
  static Animation<double> spring(
    Animation<double> parent, {
    double begin = 0,
    double end = 1,
  }) {
    return parent.drive(CurveTween(curve: AppCurves.spring)).drive(
      Tween(begin: begin, end: end),
    );
  }

  /// A one-shot controller pre-configured with the given values.
  ///
  /// Callers must dispose the returned controller.
  static AnimationController controller(
    TickerProvider vsync, {
    Duration? duration,
    double? value,
  }) {
    return AnimationController(
      vsync: vsync,
      duration: duration ?? AppDuration.medium,
      value: value,
    );
  }
}
