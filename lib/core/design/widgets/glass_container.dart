// Glass container for the Forge Design System.
//
// The foundational glass surface. Renders a translucent, blurred, softly
// bordered container that every other glass widget is built on. All visual
// parameters resolve from the [GlassThemeExtension] unless overridden.
library;

import 'package:flutter/material.dart';

import '../extensions/theme_extensions.dart';
import '../glass/glass_blur.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../glass/glass_gradient.dart';
import '../tokens/blur_tokens.dart';
import '../utilities/blur_helper.dart';

/// A frosted-glass surface with optional blur, border and layered shadows.
class GlassContainer extends StatelessWidget {
  /// Creates a glass container.
  const GlassContainer({
    super.key,
    this.decoration,
    this.padding,
    this.margin,
    this.alignment,
    this.width,
    this.height,
    this.constraints,
    this.child,
    this.semanticLabel,
    this.borderRadius,
    this.gradient,
    this.border,
    this.blur,
  });

  /// Full glass decoration. When `null` the container resolves all
  /// parameters from the ambient glass theme.
  final GlassDecoration? decoration;

  /// Inner padding applied to [child].
  final EdgeInsetsGeometry? padding;

  /// Outer margin around the glass surface.
  final EdgeInsetsGeometry? margin;

  /// Alignment of [child] inside the surface.
  final AlignmentGeometry? alignment;

  /// Fixed width.
  final double? width;

  /// Fixed height.
  final double? height;

  /// Additional box constraints.
  final BoxConstraints? constraints;

  /// The content rendered inside the glass surface.
  final Widget? child;

  /// Optional semantic label.
  final String? semanticLabel;

  /// Convenience override for the corner radius.
  final BorderRadiusGeometry? borderRadius;

  /// Convenience override for the fill gradient.
  final GlassGradient? gradient;

  /// Convenience override for the border.
  final GlassBorder? border;

  /// Convenience override for the backdrop blur.
  final GlassBlur? blur;

  @override
  Widget build(BuildContext context) {
    final decoration = (this.decoration ?? const GlassDecoration())
        .resolve(context)
        .copyWith(
          borderRadius: borderRadius,
          gradient: gradient,
          border: border,
          blur: blur,
        );

    final radius = decoration.borderRadius!.resolve(Directionality.of(context));
    final hasGradientFill = decoration.gradient != null;

    // Fill + solid border + shadows.
    Widget surface = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      alignment: alignment,
      constraints: constraints,
      decoration: BoxDecoration(
        color: hasGradientFill ? null : decoration.color,
        gradient: decoration.gradient?.toLinearGradient(),
        borderRadius: radius,
        border: decoration.border != null && decoration.border!.gradient == null
            ? Border.fromBorderSide(
                decoration.border!.toBorderSide(fallback: Colors.transparent),
              )
            : null,
      ),
      child: child,
    );

    // Gradient border + inner highlight rendered over the surface.
    if ((decoration.border?.gradient != null) || decoration.highlight) {
      surface = CustomPaint(
        painter: GlassSurfacePainter(
          radius: radius,
          border: decoration.border,
          highlightColor: decoration.highlight
              ? Theme.of(context).glass.highlightColor
              : null,
        ),
        child: surface,
      );
    }

    // Backdrop blur clipped to the rounded shape.
    final blurSigma = decoration.blur?.sigma ?? AppBlur.none;
    if (blurSigma > 0) {
      surface = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: BlurHelper.blur(blurSigma),
          child: surface,
        ),
      );
    }

    // Layered shadows drawn outside the clip.
    final shadows = decoration.shadows;
    if (shadows != null && shadows.isNotEmpty) {
      surface = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [for (final shadow in shadows) shadow.toBoxShadow()],
        ),
        child: surface,
      );
    }

    if (semanticLabel != null) {
      surface = Semantics(container: true, label: semanticLabel, child: surface);
    }
    return surface;
  }
}
