// Blur helper for the Forge Design System.
//
// Central factory for backdrop blur filters so the rendering details stay
// in one place.
library;

import 'dart:ui';

import '../tokens/blur_tokens.dart';

/// Helpers for building backdrop blur filters.
abstract final class BlurHelper {
  BlurHelper._();

  /// Builds an [ImageFilter] for a [sigma]-strength frosted blur.
  static ImageFilter blur(double sigma, {TileMode tileMode = TileMode.decal}) {
    return ImageFilter.blur(
      sigmaX: sigma,
      sigmaY: sigma,
      tileMode: tileMode,
    );
  }

  /// Builds a blur using a named token from the [AppBlur] scale.
  static ImageFilter token(double token) => blur(token);

  /// A blur that also tints the backdrop by [opacity] with black.
  static ImageFilter tinted(double sigma, {double opacity = 0.25}) {
    return ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
  }

  /// No-op filter used when a surface is not blurred.
  static ImageFilter get none => blur(AppBlur.none);
}
