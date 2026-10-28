// Page transitions for the Forge Design System.
//
// Provides a [PageTransitionsBuilder] that renders fade, slide, shared-axis
// and scale page transitions, plus route helpers for imperative pushes.
library;

import 'package:flutter/material.dart';

import 'animation_config.dart';
import '../tokens/curve_tokens.dart';
import '../tokens/duration_tokens.dart';

/// The page transition styles supported by Forge.
enum GlassPageStyle {
  /// Pure cross-fade.
  fade,

  /// Slight horizontal slide with fade.
  slide,

  /// Fade with a gentle forward slide (default).
  sharedAxis,

  /// Fade with a subtle scale.
  scale,

  /// Container-transform: scale and fade.
  container,
}

/// A [PageTransitionsBuilder] that renders a glass page transition.
class GlassPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates a page transitions builder.
  const GlassPageTransitionsBuilder({this.style = GlassPageStyle.sharedAxis});

  /// The transition style to render.
  final GlassPageStyle style;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AnimationConfig.isDisabled) return child;
    return GlassPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      style: style,
      child: child,
    );
  }
}

/// Renders a page transition for the incoming and outgoing pages.
class GlassPageTransition extends StatelessWidget {
  /// Creates a page transition.
  const GlassPageTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    this.style = GlassPageStyle.sharedAxis,
  });

  /// Primary route animation.
  final Animation<double> animation;

  /// Secondary (outgoing) route animation.
  final Animation<double> secondaryAnimation;

  /// The child being pushed onto the screen.
  final Widget child;

  /// The transition style.
  final GlassPageStyle style;

  @override
  Widget build(BuildContext context) {
    if (AnimationConfig.isDisabled) return child;
    if (style == GlassPageStyle.fade) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: AppCurves.standard),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: secondaryAnimation, curve: AppCurves.linear),
          child: child,
        ),
      );
    }

    final slideOffset = switch (style) {
      GlassPageStyle.slide => const Offset(0.06, 0),
      GlassPageStyle.sharedAxis => const Offset(0.04, 0),
      GlassPageStyle.scale || GlassPageStyle.container => Offset.zero,
      GlassPageStyle.fade => Offset.zero,
    };

    final scale = switch (style) {
      GlassPageStyle.scale || GlassPageStyle.container => 0.94,
      _ => 1.0,
    };

    final incoming = CurvedAnimation(
      parent: animation,
      curve: AppCurves.emphasized,
      reverseCurve: AppCurves.standard.flipped,
    );
    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppCurves.standard,
      reverseCurve: AppCurves.standard.flipped,
    );

    Widget result = FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: AppCurves.linear),
      child: child,
    );
    if (slideOffset != Offset.zero) {
      result = SlideTransition(
        position: Tween(begin: slideOffset, end: Offset.zero).animate(incoming),
        child: result,
      );
    }
    if (scale < 1) {
      result = ScaleTransition(
        scale: Tween(begin: scale, end: 1.0).animate(incoming),
        child: result,
      );
    }

    // Outgoing page fades and recedes.
    final outgoingOffset = slideOffset == Offset.zero ? Offset.zero : Offset(-0.03, 0);
    Widget outgoingWidget = FadeTransition(
      opacity: CurvedAnimation(parent: secondaryAnimation, curve: AppCurves.linear),
      child: SizedBox.shrink(),
    );
    return Stack(
      children: [
        SlideTransition(
          position: Tween(begin: Offset.zero, end: outgoingOffset).animate(outgoing),
          child: FadeTransition(
            opacity: outgoing,
            child: outgoingWidget,
          ),
        ),
        result,
      ],
    );
  }
}

/// Route factories for imperative glass transitions.
abstract final class GlassPageTransitions {
  GlassPageTransitions._();

  /// A route that pushes [builder] using the given [style].
  static PageRoute<T> route<T>(
    WidgetBuilder builder, {
    GlassPageStyle style = GlassPageStyle.sharedAxis,
    Duration? duration,
    bool fullscreenDialog = false,
  }) {
    return PageRouteBuilder<T>(
      fullscreenDialog: fullscreenDialog,
      transitionDuration:
          AnimationConfig.isDisabled ? Duration.zero : (duration ?? AppDuration.page),
      reverseTransitionDuration:
          AnimationConfig.isDisabled ? Duration.zero : (duration ?? AppDuration.page),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return GlassPageTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          style: style,
          child: child,
        );
      },
    );
  }

  /// A fade route.
  static PageRoute<T> fade<T>(
    WidgetBuilder builder, {
    Duration? duration,
    bool fullscreenDialog = false,
  }) {
    return route(builder,
        style: GlassPageStyle.fade,
        duration: duration,
        fullscreenDialog: fullscreenDialog);
  }

  /// A shared-axis route.
  static PageRoute<T> sharedAxis<T>(
    WidgetBuilder builder, {
    Duration? duration,
    bool fullscreenDialog = false,
  }) {
    return route(builder,
        style: GlassPageStyle.sharedAxis,
        duration: duration,
        fullscreenDialog: fullscreenDialog);
  }

  /// A slide route.
  static PageRoute<T> slide<T>(
    WidgetBuilder builder, {
    Duration? duration,
    bool fullscreenDialog = false,
  }) {
    return route(builder,
        style: GlassPageStyle.slide,
        duration: duration,
        fullscreenDialog: fullscreenDialog);
  }

  /// A scale route.
  static PageRoute<T> scale<T>(
    WidgetBuilder builder, {
    Duration? duration,
    bool fullscreenDialog = false,
  }) {
    return route(builder,
        style: GlassPageStyle.scale,
        duration: duration,
        fullscreenDialog: fullscreenDialog);
  }

  /// A container-transform route.
  static PageRoute<T> container<T>(
    WidgetBuilder builder, {
    Duration? duration,
    bool fullscreenDialog = false,
  }) {
    return route(builder,
        style: GlassPageStyle.container,
        duration: duration,
        fullscreenDialog: fullscreenDialog);
  }
}
