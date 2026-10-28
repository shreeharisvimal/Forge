// Animation theme extension for the Forge Design System.
//
// Exposes shared durations and curves through [ThemeData.extensions] so
// every widget animates with the same consistent motion vocabulary.
library;

import 'package:flutter/material.dart';

import '../tokens/curve_tokens.dart';
import '../tokens/duration_tokens.dart';

/// Motion tokens available to every Forge widget.
class AnimationThemeExtension extends ThemeExtension<AnimationThemeExtension> {
  /// Creates an animation theme extension.
  const AnimationThemeExtension({
    required this.fast,
    required this.quick,
    required this.short,
    required this.medium,
    required this.long,
    required this.slow,
    required this.standard,
    required this.emphasized,
    required this.decelerate,
    required this.accelerate,
    required this.spring,
  });

  /// Creates the default fallback animation extension.
  factory AnimationThemeExtension.fallback() {
    return const AnimationThemeExtension(
      fast: AppDuration.fast,
      quick: AppDuration.quick,
      short: AppDuration.short,
      medium: AppDuration.medium,
      long: AppDuration.long,
      slow: AppDuration.slow,
      standard: AppCurves.standard,
      emphasized: AppCurves.emphasized,
      decelerate: AppCurves.decelerate,
      accelerate: AppCurves.accelerate,
      spring: AppCurves.spring,
    );
  }

  /// Fast feedback duration (120 ms).
  final Duration fast;

  /// Quick transition duration (180 ms).
  final Duration quick;

  /// Short transition duration (240 ms).
  final Duration short;

  /// Standard transition duration (320 ms).
  final Duration medium;

  /// Emphasized transition duration (480 ms).
  final Duration long;

  /// Slow transition duration (640 ms).
  final Duration slow;

  /// Default easing curve.
  final Curve standard;

  /// Emphasized deceleration curve.
  final Curve emphasized;

  /// Departure curve.
  final Curve decelerate;

  /// Arrival curve.
  final Curve accelerate;

  /// Spring-like backing curve.
  final Curve spring;

  @override
  AnimationThemeExtension copyWith({
    Duration? fast,
    Duration? quick,
    Duration? short,
    Duration? medium,
    Duration? long,
    Duration? slow,
    Curve? standard,
    Curve? emphasized,
    Curve? decelerate,
    Curve? accelerate,
    Curve? spring,
  }) {
    return AnimationThemeExtension(
      fast: fast ?? this.fast,
      quick: quick ?? this.quick,
      short: short ?? this.short,
      medium: medium ?? this.medium,
      long: long ?? this.long,
      slow: slow ?? this.slow,
      standard: standard ?? this.standard,
      emphasized: emphasized ?? this.emphasized,
      decelerate: decelerate ?? this.decelerate,
      accelerate: accelerate ?? this.accelerate,
      spring: spring ?? this.spring,
    );
  }

  @override
  AnimationThemeExtension lerp(
      ThemeExtension<AnimationThemeExtension>? other, double t) {
    if (other is! AnimationThemeExtension) return this;
    return AnimationThemeExtension(
      fast: _lerpDuration(fast, other.fast, t),
      quick: _lerpDuration(quick, other.quick, t),
      short: _lerpDuration(short, other.short, t),
      medium: _lerpDuration(medium, other.medium, t),
      long: _lerpDuration(long, other.long, t),
      slow: _lerpDuration(slow, other.slow, t),
      standard: t < 0.5 ? standard : other.standard,
      emphasized: t < 0.5 ? emphasized : other.emphasized,
      decelerate: t < 0.5 ? decelerate : other.decelerate,
      accelerate: t < 0.5 ? accelerate : other.accelerate,
      spring: t < 0.5 ? spring : other.spring,
    );
  }
}

/// Linearly interpolates between two [Duration]s.
Duration _lerpDuration(Duration a, Duration b, double t) {
  if (t <= 0) return a;
  if (t >= 1) return b;
  return Duration(
    milliseconds:
        (a.inMilliseconds + (b.inMilliseconds - a.inMilliseconds) * t).round(),
  );
}
