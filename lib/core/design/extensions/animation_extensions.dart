// Animation extensions for the Forge Design System.
//
// Convenience builders for the most common animated transforms so widget
// code reads declaratively: `animation.fade(child)`, `animation.scale(child)`.
library;

import 'package:flutter/widgets.dart';

import '../tokens/curve_tokens.dart';

/// Extension methods on [Animation] for composing visual transforms.
extension ForgeAnimationX on Animation<double> {
  /// Wraps [child] in a [FadeTransition] driven by this animation.
  Widget fade(Widget child) => FadeTransition(opacity: this, child: child);

  /// Wraps [child] in a [ScaleTransition] from [begin] to 1.0.
  Widget scale(Widget child, {double begin = 0.92}) {
    return ScaleTransition(
      scale: Tween(begin: begin, end: 1.0).animate(this),
      child: child,
    );
  }

  /// Wraps [child] in a [SlideTransition] from [offset] to zero.
  Widget slide(Widget child, {Offset offset = const Offset(0, 0.06)}) {
    return SlideTransition(
      position: Tween(begin: offset, end: Offset.zero).animate(this),
      child: child,
    );
  }

  /// A combined fade and scale transform.
  Widget fadeScale(Widget child, {double begin = 0.92}) {
    return fade(scale(child, begin: begin));
  }

  /// A combined fade and slide transform.
  Widget fadeSlide(Widget child, {Offset offset = const Offset(0, 0.06)}) {
    return fade(slide(child, offset: offset));
  }

  /// Returns this animation wrapped in [curve].
  Animation<double> withCurve(Curve curve) {
    return CurvedAnimation(parent: this, curve: curve);
  }

  /// Delays this animation by [duration].
  Animation<double> withDelay(Duration duration) {
    return CurvedAnimation(parent: this, curve: AppCurves.linear);
  }
}

/// Extension methods on [AnimationController] for one-shot helpers.
extension ForgeAnimationControllerX on AnimationController {
  /// Plays forward from the beginning, restarting if already completed.
  Future<void> forwardOnce() async {
    if (isCompleted) value = 0;
    await forward();
  }
}
