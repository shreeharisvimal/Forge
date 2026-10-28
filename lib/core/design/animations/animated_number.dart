// Animated number for the Forge Design System.
//
// Smoothly tweens a numeric value and renders it as text, giving stats and
// metrics a premium counting feel.
library;

import 'package:flutter/material.dart';

import '../tokens/curve_tokens.dart';
import '../utilities/animation_helper.dart';

/// A text widget that animates numeric value changes.
class GlassAnimatedNumber extends StatelessWidget {
  /// Creates an animated number.
  const GlassAnimatedNumber({
    super.key,
    required this.value,
    this.style,
    this.duration,
    this.curve,
    this.decimals = 0,
    this.formatter,
    this.semanticValue,
  });

  /// The number to display and animate toward.
  final double value;

  /// Optional text style.
  final TextStyle? style;

  /// Animation duration (defaults to the theme's short duration).
  final Duration? duration;

  /// Animation curve.
  final Curve? curve;

  /// Number of decimals to render.
  final int decimals;

  /// Optional custom formatter (receives the interpolated value).
  final String Function(double value)? formatter;

  /// Optional override for the screen-reader label.
  final String? semanticValue;

  @override
  Widget build(BuildContext context) {
    final duration = AnimationHelper.durationOf(context, duration: this.duration);
    return Semantics(
      label: semanticValue ?? formatter?.call(value) ?? value.toStringAsFixed(decimals),
      liveRegion: true,
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value),
          duration: duration,
          curve: curve ?? AppCurves.standard,
          builder: (context, animatedValue, _) {
            return Text(
              formatter?.call(animatedValue) ??
                  animatedValue.toStringAsFixed(decimals),
              style: style,
            );
          },
        ),
      ),
    );
  }
}
