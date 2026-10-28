// Gradient descriptor for the Forge Design System.
//
// A value object describing a linear gradient so surfaces can specify
// gradients without coupling to rendering.
library;

import 'package:flutter/material.dart';

/// Describes a linear gradient for a glass surface.
class GlassGradient {
  /// Creates a gradient descriptor.
  const GlassGradient({
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.stops,
  });

  /// Gradient color stops.
  final List<Color> colors;

  /// Starting corner.
  final AlignmentGeometry begin;

  /// Ending corner.
  final AlignmentGeometry end;

  /// Optional color-stop offsets.
  final List<double>? stops;

  /// Converts this descriptor into a [LinearGradient].
  LinearGradient toLinearGradient() {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
      stops: stops,
    );
  }
}
