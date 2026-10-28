// Shadow descriptor for the Forge Design System.
//
// A value object describing a single layered shadow. Multiple shadows are
// composed through the decoration to create the layered glass depth.
library;

import 'package:flutter/material.dart';

/// Describes a single shadow for a glass surface.
class GlassShadow {
  /// Creates a shadow descriptor.
  const GlassShadow({
    required this.color,
    this.blurRadius = 16,
    this.offset = Offset.zero,
    this.spreadRadius = 0,
  });

  /// Shadow color.
  final Color color;

  /// Shadow softness.
  final double blurRadius;

  /// Shadow offset.
  final Offset offset;

  /// Shadow growth before blurring.
  final double spreadRadius;

  /// Converts this descriptor into a [BoxShadow].
  BoxShadow toBoxShadow() {
    return BoxShadow(
      color: color,
      blurRadius: blurRadius,
      offset: offset,
      spreadRadius: spreadRadius,
    );
  }

  /// Builds a descriptor from an existing [BoxShadow].
  factory GlassShadow.fromBoxShadow(BoxShadow shadow) {
    return GlassShadow(
      color: shadow.color,
      blurRadius: shadow.blurRadius,
      offset: shadow.offset,
      spreadRadius: shadow.spreadRadius,
    );
  }
}
