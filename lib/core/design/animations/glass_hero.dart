// Hero motion wrapper for the Forge Design System.
//
// GlassHero is a themed [Hero] whose flight animation can be container
// transform (scale + fade), shared axis (slide + fade) or plain fade.
library;

import 'package:flutter/material.dart';

import '../tokens/curve_tokens.dart';

/// The flight animation styles supported by [GlassHero].
enum GlassHeroMotion {
  /// Container-transform style: scale and fade during flight.
  container,

  /// Shared-axis style: slide and fade during flight.
  sharedAxis,

  /// Simple cross-fade.
  fade,
}

/// A [Hero] with a themed flight animation.
class GlassHero extends StatelessWidget {
  /// Creates a themed hero.
  const GlassHero({
    super.key,
    required this.tag,
    required this.child,
    this.motion = GlassHeroMotion.container,
    this.duration,
    this.curve,
  });

  /// The unique tag identifying this hero.
  final Object tag;

  /// The hero's resting child.
  final Widget child;

  /// The flight animation style.
  final GlassHeroMotion motion;

  /// Optional flight duration (defaults to the theme's long duration).
  final Duration? duration;

  /// Optional flight curve.
  final Curve? curve;

  @override
  Widget build(BuildContext context) {
    final curve = this.curve ?? AppCurves.standard;
    return Hero(
      tag: tag,
      createRectTween: (begin, end) => RectTween(begin: begin, end: end),
      flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
        final toChild = toHeroContext.widget is Hero
            ? (toHeroContext.widget as Hero).child
            : child;
        return _GlassHeroShuttle(
          animation: animation,
          motion: motion,
          curve: curve,
          child: toChild,
        );
      },
      child: child,
    );
  }
}

/// Renders the animated child during a hero flight.
class _GlassHeroShuttle extends StatelessWidget {
  const _GlassHeroShuttle({
    required this.child,
    required this.animation,
    required this.motion,
    required this.curve,
  });

  final Widget child;
  final Animation<double> animation;
  final GlassHeroMotion motion;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: curve);
    return switch (motion) {
      GlassHeroMotion.container => FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      GlassHeroMotion.sharedAxis => FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        ),
      GlassHeroMotion.fade => FadeTransition(opacity: curved, child: child),
    };
  }
}
