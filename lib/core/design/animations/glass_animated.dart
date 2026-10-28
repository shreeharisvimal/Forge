// Entrance animation wrapper for the Forge Design System.
//
// GlassAnimated plays a mount animation for its child, choosing between a
// fade, scale, slide, spring or no entrance. Every Forge widget can opt in
// to an entrance through this widget.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/curve_tokens.dart';
import '../tokens/duration_tokens.dart';
import '../utilities/animation_helper.dart';

/// The entrance animation styles supported by [GlassAnimated].
enum GlassEntrance {
  /// No animation.
  none,

  /// Pure opacity fade-in.
  fade,

  /// Fade with a subtle scale-up.
  scale,

  /// Fade with a slide from [GlassAnimated.offset].
  slide,

  /// Fade with a springy scale bounce.
  spring,
}

/// Plays a mount animation for its child.
class GlassAnimated extends StatefulWidget {
  /// Creates an entrance wrapper.
  const GlassAnimated({
    super.key,
    required this.child,
    this.entrance = GlassEntrance.fade,
    this.duration,
    this.curve,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.06),
  });

  /// Fade-only entrance.
  const GlassAnimated.fade({super.key, required this.child, this.duration, this.curve, this.delay = Duration.zero})
      : entrance = GlassEntrance.fade,
        offset = const Offset(0, 0.06);

  /// Scale entrance.
  const GlassAnimated.scale({super.key, required this.child, this.duration, this.curve, this.delay = Duration.zero})
      : entrance = GlassEntrance.scale,
        offset = const Offset(0, 0.06);

  /// Slide entrance.
  const GlassAnimated.slide({super.key, required this.child, this.duration, this.curve, this.delay = Duration.zero, this.offset = const Offset(0, 0.06)})
      : entrance = GlassEntrance.slide;

  /// Spring entrance.
  const GlassAnimated.spring({super.key, required this.child, this.duration, this.curve, this.delay = Duration.zero})
      : entrance = GlassEntrance.spring,
        offset = const Offset(0, 0.06);

  /// The child being animated in.
  final Widget child;

  /// The entrance style to play.
  final GlassEntrance entrance;

  /// Animation duration (defaults to the theme's short duration).
  final Duration? duration;

  /// Animation curve.
  final Curve? curve;

  /// Delay before the entrance starts.
  final Duration delay;

  /// Fractional slide distance used by the [GlassEntrance.slide] style.
  final Offset offset;

  @override
  State<GlassAnimated> createState() => _GlassAnimatedState();
}

class _GlassAnimatedState extends State<GlassAnimated>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationHelper.controller(
      this,
      duration: widget.duration ?? AppDuration.short,
    );
    _controller.addStatusListener(_onStatus);
    if (widget.delay > Duration.zero) {
      _delayTimer = Timer(widget.delay, _controller.forward);
    } else {
      _controller.forward();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _controller.removeStatusListener(_onStatus);
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entrance == GlassEntrance.none) return widget.child;

    final curve = widget.curve ?? AppCurves.standard;
    final animation = CurvedAnimation(parent: _controller, curve: curve);

    switch (widget.entrance) {
      case GlassEntrance.none:
        return widget.child;
      case GlassEntrance.fade:
        return FadeTransition(opacity: animation, child: widget.child);
      case GlassEntrance.scale:
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0)
                .animate(CurvedAnimation(parent: _controller, curve: AppCurves.spring)),
            child: widget.child,
          ),
        );
      case GlassEntrance.slide:
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween(begin: widget.offset, end: Offset.zero).animate(animation),
            child: widget.child,
          ),
        );
      case GlassEntrance.spring:
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.88, end: 1.0)
                .animate(CurvedAnimation(parent: _controller, curve: AppCurves.spring)),
            child: widget.child,
          ),
        );
    }
  }
}
