// Animation curve tokens for the Forge Design System.
//
// Every easing curve used in the application must come from this scale.
// Consistent curves keep motion feeling natural and premium.
library;

import 'package:flutter/animation.dart';

/// The shared animation curve scale for Forge.
abstract final class AppCurves {
  AppCurves._();

  /// Linear interpolation.
  static const Curve linear = Curves.linear;

  /// Default easing for most motion.
  static const Curve standard = Curves.easeInOutCubic;

  /// Emphasized deceleration for entrances.
  static const Curve emphasized = Curves.easeOutCubic;

  /// Fast start, gentle stop (departures).
  static const Curve decelerate = Curves.easeOutQuad;

  /// Gentle start, fast finish (arrivals).
  static const Curve accelerate = Curves.easeInQuad;

  /// Backing overshoot for spring-like entrances.
  static const Curve spring = Curves.easeOutBack;

  /// Bouncy overshoot for celebratory moments.
  static const Curve bounce = Curves.elasticOut;

  /// Slow, sinusoidal drift for ambient background motion.
  static const Curve backgroundDrift = Curves.easeInOutSine;

  /// Returns [curve] if provided, otherwise the [standard] curve.
  static Curve resolve(Curve? curve) => curve ?? standard;
}
