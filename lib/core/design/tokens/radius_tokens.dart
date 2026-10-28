// Corner radius tokens for the Forge Design System.
//
// Every rounded corner in the application must come from this scale.
// Matches the Forge v3 specification (cards 24, buttons 18, inputs 18,
// dialogs 28, FAB 22, bottom sheet 32).
library;

import 'package:flutter/material.dart';

/// The shared corner radius scale for Forge.
abstract final class AppRadius {
  AppRadius._();

  /// 8 dp — fine controls and small chips.
  static const double extraSmall = 8;

  /// 12 dp — list tiles and small elements.
  static const double small = 12;

  /// 16 dp — inputs and search fields.
  static const double input = 16;

  /// 18 dp — buttons.
  static const double medium = 18;

  /// 16 dp — inputs and search fields.
  static const double inputRadius = input;

  /// A [BorderRadius] built from [input].
  static BorderRadius get inputBorderRadius => BorderRadius.circular(input);

  /// 24 dp — cards and content surfaces.
  static const double large = 24;

  /// 28 dp — dialogs and hero surfaces.
  static const double extraLarge = 28;

  /// 22 dp — floating action buttons.
  static const double fab = 22;

  /// 32 dp — bottom sheets and modals.
  static const double sheet = 32;

  /// A [BorderRadius] built from [small].
  static BorderRadius get smallRadius => BorderRadius.circular(small);

  /// A [BorderRadius] built from [medium].
  static BorderRadius get mediumRadius => BorderRadius.circular(medium);

  /// A [BorderRadius] built from [large].
  static BorderRadius get largeRadius => BorderRadius.circular(large);

  /// A [BorderRadius] built from [extraLarge].
  static BorderRadius get extraLargeRadius => BorderRadius.circular(extraLarge);

  /// A [BorderRadius] built from [fab].
  static BorderRadius get fabRadius => BorderRadius.circular(fab);

  /// A [BorderRadius] built from [sheet].
  static BorderRadius get sheetRadius => BorderRadius.circular(sheet);
}
