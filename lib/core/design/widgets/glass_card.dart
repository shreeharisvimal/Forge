// Glass card for the Forge Design System.
//
// The standard content surface. A glass container with default padding and
// an optional tap interaction and entrance animation.
library;

import 'package:flutter/material.dart';

import '../animations/glass_animated.dart';
import '../extensions/theme_extensions.dart';
import '../glass/glass_decoration.dart';
import '../tokens/spacing_tokens.dart';
import 'glass_container.dart';
import 'glass_pressable.dart';

/// A rounded frosted-glass card.
class GlassCard extends StatelessWidget {
  /// Creates a glass card.
  const GlassCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.decoration,
    this.onTap,
    this.semanticLabel,
    this.entrance = GlassEntrance.none,
    this.duration,
    this.borderRadius,
    this.highlight = true,
  });

  /// The card content.
  final Widget? child;

  /// Inner padding (defaults to the theme's lg spacing).
  final EdgeInsetsGeometry? padding;

  /// Outer margin.
  final EdgeInsetsGeometry? margin;

  /// Optional glass decoration override.
  final GlassDecoration? decoration;

  /// Invoked when the card is tapped.
  final VoidCallback? onTap;

  /// Optional semantic label.
  final String? semanticLabel;

  /// Optional entrance animation.
  final GlassEntrance entrance;

  /// Entrance animation duration.
  final Duration? duration;

  /// Corner radius override.
  final BorderRadiusGeometry? borderRadius;

  /// Whether to draw the soft inner highlight.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final resolved = (decoration ?? const GlassDecoration())
        .resolve(context)
        .copyWith(highlight: highlight);

    Widget surface = GlassContainer(
      decoration: resolved,
      padding: padding ?? AppSpacing.lg.all,
      margin: margin,
      borderRadius: borderRadius,
      child: child,
    );

    if (onTap != null) {
      surface = GlassPressable(
        onTap: onTap,
        semanticLabel: semanticLabel,
        borderRadius: BorderRadius.circular(
          Theme.of(context).glass.borderRadius,
        ),
        child: surface,
      );
    }

    if (entrance != GlassEntrance.none) {
      surface = GlassAnimated(
        entrance: entrance,
        duration: duration,
        child: surface,
      );
    }
    return surface;
  }
}
