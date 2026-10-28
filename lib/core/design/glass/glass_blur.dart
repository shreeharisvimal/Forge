// Backdrop blur descriptor for the Forge Design System.
//
// Carries the sigma and tinting of a frosted-glass blur so surfaces can
// describe their blur without knowing how it is rendered.
library;

import 'dart:ui';

/// Describes a backdrop blur for a glass surface.
class GlassBlur {
  /// Creates a blur descriptor.
  const GlassBlur(this.sigma, {this.tint = false});

  /// Blur strength in sigma units.
  final double sigma;

  /// Whether the surface should additionally darken its backdrop.
  final bool tint;

  /// An [ImageFilter] that applies this blur.
  ImageFilter toImageFilter() {
    return ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal);
  }
}
