// Border descriptor for the Forge Design System.
//
// A glass border is either a solid low-opacity line or a gradient stroke.
// The descriptor is rendered by the glass decoration painter.
library;

import 'package:flutter/material.dart';

import 'glass_gradient.dart';

/// Describes the border of a glass surface.
class GlassBorder {
  /// Creates a border descriptor.
  const GlassBorder({
    this.color,
    this.gradient,
    this.width = 1,
  });

  /// Solid border color (ignored when [gradient] is provided).
  final Color? color;

  /// Gradient border stroke.
  final GlassGradient? gradient;

  /// Border width.
  final double width;

  /// Whether this border is invisible.
  bool get isNone => width == 0 && color == null && gradient == null;

  /// Converts this descriptor into a [BorderSide].
  BorderSide toBorderSide({Color? fallback}) {
    return BorderSide(color: color ?? fallback ?? Colors.transparent, width: width);
  }
}
