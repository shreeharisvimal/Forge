// Glass decoration for the Forge Design System.
//
// The composite descriptor that powers every glass surface. It combines a
// translucent fill, an optional gradient, a border, layered shadows and a
// backdrop blur, resolving its unspecified fields from the
// [GlassThemeExtension].
library;

import 'package:flutter/material.dart';

import '../theme/glass_theme_extension.dart';
import 'glass_blur.dart';
import 'glass_border.dart';
import 'glass_gradient.dart';
import 'glass_shadow.dart';

/// A complete visual description of a glass surface.
class GlassDecoration {
  /// Creates a glass decoration.
  const GlassDecoration({
    this.color,
    this.gradient,
    this.borderRadius,
    this.border,
    this.shadows,
    this.blur,
    this.highlight = true,
  });

  /// Solid translucent fill color.
  final Color? color;

  /// Optional gradient fill.
  final GlassGradient? gradient;

  /// Corner radius.
  final BorderRadiusGeometry? borderRadius;

  /// Optional border (solid or gradient).
  final GlassBorder? border;

  /// Layered shadows.
  final List<GlassShadow>? shadows;

  /// Optional backdrop blur.
  final GlassBlur? blur;

  /// Whether to draw a soft inner top highlight.
  final bool highlight;

  /// Copies this decoration, keeping every field that is not provided.
  GlassDecoration copyWith({
    Color? color,
    GlassGradient? gradient,
    BorderRadiusGeometry? borderRadius,
    GlassBorder? border,
    List<GlassShadow>? shadows,
    GlassBlur? blur,
    bool? highlight,
  }) {
    return GlassDecoration(
      color: color ?? this.color,
      gradient: gradient ?? this.gradient,
      borderRadius: borderRadius ?? this.borderRadius,
      border: border ?? this.border,
      shadows: shadows ?? this.shadows,
      blur: blur ?? this.blur,
      highlight: highlight ?? this.highlight,
    );
  }

  /// Resolves this decoration against the ambient [GlassThemeExtension].
  ///
  /// Every field that was left `null` is filled from the theme so callers
  /// only override what they need. Layered soft shadows come from the theme
  /// so elevation stays consistent app-wide.
  GlassDecoration resolve(BuildContext context) {
    final glass =
        Theme.of(context).extension<GlassThemeExtension>() ??
            GlassThemeExtension.fallback();
    return GlassDecoration(
      color: color ?? glass.glassColor,
      gradient: gradient,
      borderRadius: borderRadius ?? BorderRadius.circular(glass.borderRadius),
      border: border ??
          GlassBorder(color: glass.borderColor, width: glass.borderWidth),
      shadows: shadows ??
          [for (final shadow in glass.shadows) GlassShadow.fromBoxShadow(shadow)],
      blur: blur ?? GlassBlur(glass.blur),
      highlight: highlight,
    );
  }
}

/// Paints the gradient border and inner highlight of a glass surface.
///
/// Rendered as a [CustomPaint] overlay so gradient borders and soft inner
/// glows stay crisp inside the rounded clip.
class GlassSurfacePainter extends CustomPainter {
  /// Creates the painter.
  const GlassSurfacePainter({
    required this.radius,
    this.border,
    this.highlightColor,
  });

  /// Corner radius of the surface.
  final BorderRadius radius;

  /// Optional border to paint.
  final GlassBorder? border;

  /// Optional inner highlight color.
  final Color? highlightColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: radius.topLeft,
      topRight: radius.topRight,
      bottomLeft: radius.bottomLeft,
      bottomRight: radius.bottomRight,
    );

    if (border != null && !border!.isNone) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = border!.width;
      if (border!.gradient != null) {
        paint.shader = border!.gradient!.toLinearGradient().createShader(rect);
      } else {
        paint.color = border!.color ?? Colors.transparent;
      }
      canvas.drawRRect(rrect, paint);
    }

    if (highlightColor != null) {
      final inner = rrect.deflate(border?.width ?? 0);
      final rectPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [highlightColor!, Colors.transparent],
          stops: const [0.0, 0.55],
        ).createShader(rect);
      canvas.drawRRect(inner, rectPaint);
    }
  }

  @override
  bool shouldRepaint(GlassSurfacePainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.border != border ||
        oldDelegate.highlightColor != highlightColor;
  }
}
