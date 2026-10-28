// Accent palette catalog for the Forge Design System.
//
// An accent is the brand pair (primary + secondary) plus the gradient
// ramps derived from them, in both dark and light variants. The settings
// feature turns these raw palettes into user-facing choices; the theme
// factory consumes them to build [ThemeData]. Keeping the palette data in
// the design layer means themes never depend on feature code.
library;

import 'package:flutter/material.dart';

import '../tokens/gradient_presets.dart';
import 'forge_colors.dart';

/// The colors that define one selectable accent.
class ForgeAccentPalette {
  /// Creates an accent palette.
  const ForgeAccentPalette({
    required this.key,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.primaryGradient,
    required this.secondaryGradient,
    required this.primaryToSecondary,
    required this.lightPrimary,
    required this.lightSecondary,
    required this.lightPrimaryGradient,
    required this.lightPrimaryToSecondary,
  });

  /// Stable identifier stored in [SettingsModel.accentColor].
  final String key;

  /// Human-readable label.
  final String name;

  /// Dark-mode brand primary.
  final Color primary;

  /// Dark-mode brand secondary.
  final Color secondary;

  /// Dark-mode primary ramp (identical to [AppGradients.primary] for the
  /// default violet accent so default rendering never shifts).
  final List<Color> primaryGradient;

  /// Dark-mode secondary ramp.
  final List<Color> secondaryGradient;

  /// Dark-mode primary-to-secondary signature gradient.
  final List<Color> primaryToSecondary;

  /// Light-mode brand primary (deepened for contrast on light surfaces).
  final Color lightPrimary;

  /// Light-mode brand secondary.
  final Color lightSecondary;

  /// Light-mode primary ramp.
  final List<Color> lightPrimaryGradient;

  /// Light-mode signature gradient.
  final List<Color> lightPrimaryToSecondary;
}

/// The catalog of selectable accent palettes.
abstract final class ForgeAccentPalettes {
  ForgeAccentPalettes._();

  /// The default violet accent — the Forge brand identity.
  static const ForgeAccentPalette violet = ForgeAccentPalette(
    key: 'violet',
    name: 'Violet',
    primary: ForgeColors.primary,
    secondary: ForgeColors.secondary,
    primaryGradient: AppGradients.primary,
    secondaryGradient: AppGradients.secondary,
    primaryToSecondary: AppGradients.primaryToSecondary,
    lightPrimary: Color(0xFF5E35B1),
    lightSecondary: Color(0xFF00838F),
    lightPrimaryGradient: [Color(0xFF5E35B1), Color(0xFF9575CD)],
    lightPrimaryToSecondary: [Color(0xFF5E35B1), Color(0xFF00838F)],
  );

  /// A blue accent.
  static const ForgeAccentPalette blue = ForgeAccentPalette(
    key: 'blue',
    name: 'Blue',
    primary: Color(0xFF2979FF),
    secondary: Color(0xFF00B8D4),
    primaryGradient: [Color(0xFF2979FF), Color(0xFF82B1FF)],
    secondaryGradient: [Color(0xFF00B8D4), Color(0xFF80DEEA)],
    primaryToSecondary: [Color(0xFF2979FF), Color(0xFF00B8D4)],
    lightPrimary: Color(0xFF1565C0),
    lightSecondary: Color(0xFF00838F),
    lightPrimaryGradient: [Color(0xFF1565C0), Color(0xFF64B5F6)],
    lightPrimaryToSecondary: [Color(0xFF1565C0), Color(0xFF00838F)],
  );

  /// A cyan accent.
  static const ForgeAccentPalette cyan = ForgeAccentPalette(
    key: 'cyan',
    name: 'Cyan',
    primary: Color(0xFF00ACC1),
    secondary: Color(0xFF7C4DFF),
    primaryGradient: [Color(0xFF00ACC1), Color(0xFF4DD0E1)],
    secondaryGradient: AppGradients.primary,
    primaryToSecondary: [Color(0xFF00ACC1), Color(0xFF7C4DFF)],
    lightPrimary: Color(0xFF00838F),
    lightSecondary: Color(0xFF5E35B1),
    lightPrimaryGradient: [Color(0xFF00838F), Color(0xFF4DD0E1)],
    lightPrimaryToSecondary: [Color(0xFF00838F), Color(0xFF5E35B1)],
  );

  /// A teal accent.
  static const ForgeAccentPalette teal = ForgeAccentPalette(
    key: 'teal',
    name: 'Teal',
    primary: Color(0xFF1DE9B6),
    secondary: Color(0xFF00E5FF),
    primaryGradient: [Color(0xFF1DE9B6), Color(0xFF69F0AE)],
    secondaryGradient: AppGradients.secondary,
    primaryToSecondary: [Color(0xFF1DE9B6), Color(0xFF00E5FF)],
    lightPrimary: Color(0xFF00897B),
    lightSecondary: Color(0xFF00838F),
    lightPrimaryGradient: [Color(0xFF00897B), Color(0xFF4DB6AC)],
    lightPrimaryToSecondary: [Color(0xFF00897B), Color(0xFF00838F)],
  );

  /// A green accent.
  static const ForgeAccentPalette green = ForgeAccentPalette(
    key: 'green',
    name: 'Green',
    primary: Color(0xFF00E676),
    secondary: Color(0xFFAEEA00),
    primaryGradient: AppGradients.success,
    secondaryGradient: [Color(0xFFAEEA00), Color(0xFFD4E157)],
    primaryToSecondary: [Color(0xFF00E676), Color(0xFFAEEA00)],
    lightPrimary: Color(0xFF00A152),
    lightSecondary: Color(0xFF9E9D24),
    lightPrimaryGradient: [Color(0xFF00A152), Color(0xFF66BB6A)],
    lightPrimaryToSecondary: [Color(0xFF00A152), Color(0xFF9E9D24)],
  );

  /// An amber accent.
  static const ForgeAccentPalette amber = ForgeAccentPalette(
    key: 'amber',
    name: 'Amber',
    primary: Color(0xFFFFB300),
    secondary: Color(0xFFFF7043),
    primaryGradient: [Color(0xFFFFB300), Color(0xFFFFE082)],
    secondaryGradient: AppGradients.warning,
    primaryToSecondary: [Color(0xFFFFB300), Color(0xFFFF7043)],
    lightPrimary: Color(0xFFF57F17),
    lightSecondary: Color(0xFFE64A19),
    lightPrimaryGradient: [Color(0xFFF57F17), Color(0xFFFFD54F)],
    lightPrimaryToSecondary: [Color(0xFFF57F17), Color(0xFFE64A19)],
  );

  /// An orange accent.
  static const ForgeAccentPalette orange = ForgeAccentPalette(
    key: 'orange',
    name: 'Orange',
    primary: Color(0xFFFF7043),
    secondary: Color(0xFFFFB300),
    primaryGradient: AppGradients.danger,
    secondaryGradient: [Color(0xFFFFB300), Color(0xFFFFE082)],
    primaryToSecondary: [Color(0xFFFF7043), Color(0xFFFFB300)],
    lightPrimary: Color(0xFFE64A19),
    lightSecondary: Color(0xFFF57F17),
    lightPrimaryGradient: [Color(0xFFE64A19), Color(0xFFFF8A65)],
    lightPrimaryToSecondary: [Color(0xFFE64A19), Color(0xFFF57F17)],
  );

  /// A red accent.
  static const ForgeAccentPalette red = ForgeAccentPalette(
    key: 'red',
    name: 'Red',
    primary: Color(0xFFFF5252),
    secondary: Color(0xFFFF7043),
    primaryGradient: [Color(0xFFFF5252), Color(0xFFFF8A80)],
    secondaryGradient: AppGradients.danger,
    primaryToSecondary: [Color(0xFFFF5252), Color(0xFFFF7043)],
    lightPrimary: Color(0xFFD32F2F),
    lightSecondary: Color(0xFFE64A19),
    lightPrimaryGradient: [Color(0xFFD32F2F), Color(0xFFE57373)],
    lightPrimaryToSecondary: [Color(0xFFD32F2F), Color(0xFFE64A19)],
  );

  /// A pink accent.
  static const ForgeAccentPalette pink = ForgeAccentPalette(
    key: 'pink',
    name: 'Pink',
    primary: Color(0xFFF06292),
    secondary: Color(0xFFBA68C8),
    primaryGradient: [Color(0xFFF06292), Color(0xFFF48FB1)],
    secondaryGradient: [Color(0xFFBA68C8), Color(0xFFCE93D8)],
    primaryToSecondary: [Color(0xFFF06292), Color(0xFFBA68C8)],
    lightPrimary: Color(0xFFC2185B),
    lightSecondary: Color(0xFF8E24AA),
    lightPrimaryGradient: [Color(0xFFC2185B), Color(0xFFF06292)],
    lightPrimaryToSecondary: [Color(0xFFC2185B), Color(0xFF8E24AA)],
  );

  /// Every accent in stable display order.
  static const List<ForgeAccentPalette> all = [
    violet,
    blue,
    cyan,
    teal,
    green,
    amber,
    orange,
    red,
    pink,
  ];

  /// The palette for [key], or the default violet accent when unknown.
  static ForgeAccentPalette byKey(String? key) {
    for (final palette in all) {
      if (palette.key == key) return palette;
    }
    return violet;
  }
}
