// Gradient preset tokens for the Forge Design System.
//
// Every gradient used across the application must come from these presets
// so brand colors stay consistent and editable in one place.
library;

import 'package:flutter/material.dart';

import '../colors/forge_colors.dart';

/// Shared gradient presets for Forge.
abstract final class AppGradients {
  AppGradients._();

  /// Primary indigo ramp.
  static const List<Color> primary = [
    ForgeColors.primary,
    Color(0xFF9A6BFF),
  ];

  /// Secondary violet ramp.
  static const List<Color> secondary = [
    ForgeColors.secondary,
    ForgeColors.primary,
  ];

  /// Signature indigo-to-violet brand gradient.
  static const List<Color> primaryToSecondary = [
    ForgeColors.primary,
    ForgeColors.secondary,
  ];

  /// Success ramp.
  static const List<Color> success = [
    ForgeColors.success,
    Color(0xFF4ADE80),
  ];

  /// Warning ramp.
  static const List<Color> warning = [
    ForgeColors.warning,
    Color(0xFFFBBF24),
  ];

  /// Danger ramp.
  static const List<Color> danger = [
    ForgeColors.danger,
    Color(0xFFF87171),
  ];

  /// Info ramp.
  static const List<Color> info = [
    ForgeColors.info,
    Color(0xFF7DD3FC),
  ];

  /// Neutral white glass ramp.
  static const List<Color> glass = [
    Color(0x14FFFFFF),
    Color(0x08FFFFFF),
  ];

  /// Builds a [LinearGradient] from a preset color list.
  ///
  /// Defaults to a top-left to bottom-right sweep.
  static LinearGradient linear(
    List<Color> colors, {
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    List<double>? stops,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
      stops: stops,
    );
  }
}
