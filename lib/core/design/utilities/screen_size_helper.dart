// Screen size helper for the Forge Design System.
//
// Thin accessors over [MediaQuery] for common geometry questions. Kept
// separate from the responsive breakpoint helper because it deals with raw
// dimensions rather than layout classes.
library;

import 'package:flutter/material.dart';

import '../tokens/spacing_tokens.dart';

/// Helpers for reading screen geometry.
abstract final class ScreenSize {
  ScreenSize._();

  /// The current screen size.
  static Size sizeOf(BuildContext context) => MediaQuery.sizeOf(context);

  /// The current screen width.
  static double widthOf(BuildContext context) => MediaQuery.sizeOf(context).width;

  /// The current screen height.
  static double heightOf(BuildContext context) => MediaQuery.sizeOf(context).height;

  /// The shortest screen side (good for tablet detection).
  static double shortestSideOf(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.shortestSide;
  }

  /// Whether the layout is landscape.
  static bool isLandscape(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width > size.height;
  }

  /// Whether the device is tablet-sized or larger.
  static bool isTablet(BuildContext context) {
    return shortestSideOf(context) >= responsiveTabletThreshold;
  }

  /// A width-constrained content size for adaptive layouts.
  ///
  /// Never exceeds [AppSpacing.maxContentWidth] so content stays readable
  /// on desktop.
  static double maxContentWidth(BuildContext context) {
    final width = widthOf(context);
    return width < AppSpacing.maxContentWidth ? width : AppSpacing.maxContentWidth;
  }

  /// The safe-area padding around the screen.
  static EdgeInsets paddingOf(BuildContext context) {
    return MediaQuery.paddingOf(context);
  }

  /// The top safe-area inset.
  static double safeTop(BuildContext context) => paddingOf(context).top;

  /// The bottom safe-area inset.
  static double safeBottom(BuildContext context) => paddingOf(context).bottom;
}

/// Minimum shortest side for tablet-sized layouts (Material guidance).
const double responsiveTabletThreshold = 600;
