// Semantic color palette for the Forge Design System.
//
// Single source of truth for every color used by the Forge design system.
// Values match the Forge v3 specification: pure-AMOLED black background,
// a cool dark surface ramp (0B0B0C / 111214 / 18191C), a single indigo
// accent and subtle white-alpha glass tones.
library;

import 'package:flutter/material.dart';

/// Raw brand palette for Forge.
///
/// Kept as raw [Color] values (not scheme roles) so the [ColorScheme] and
/// the [ColorThemeExtension] are the only places that map them to
/// semantic tokens.
abstract final class ForgeColors {
  ForgeColors._();

  // ---------------------------------------------------------------------
  // Brand.
  // ---------------------------------------------------------------------

  /// Primary brand indigo used for highlights and selected states.
  static const Color primary = Color(0xFF7C4DFF);

  /// Content color placed on top of [primary].
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Secondary brand violet used for subtle accents and secondary actions.
  static const Color secondary = Color(0xFFB388FF);

  /// Content color placed on top of [secondary].
  static const Color onSecondary = Color(0xFF1A0B2E);

  // ---------------------------------------------------------------------
  // Feedback.
  // ---------------------------------------------------------------------

  /// Success feedback color.
  static const Color success = Color(0xFF22C55E);

  /// Warning feedback color.
  static const Color warning = Color(0xFFF59E0B);

  /// Danger / destructive feedback color.
  static const Color danger = Color(0xFFEF4444);

  /// Informational feedback color.
  static const Color info = Color(0xFF38BDF8);

  // ---------------------------------------------------------------------
  // Surfaces — pure black background keeps AMOLED pixels off.
  // ---------------------------------------------------------------------

  /// App scaffold background (true black for OLED screens).
  static const Color background = Color(0xFF000000);

  /// A barely-lifted tint of the background used to add depth.
  static const Color backgroundRaised = Color(0xFF0B0B0C);

  /// Ambient indigo glow used in the shell background.
  static const Color glowViolet = Color(0xFF7C4DFF);

  /// Ambient deep-indigo glow used in the shell background.
  static const Color glowCyan = Color(0xFF3D2B8C);

  /// Deep violet glow that grounds the background's lower edge.
  static const Color glowVioletDeep = Color(0xFF241457);

  /// Default frosted surface for cards, sheets and bars.
  static const Color surface = Color(0xFF111214);

  /// Surface layer closest to the background.
  static const Color surfaceLow = Color(0xFF0B0B0C);

  /// Elevated surface layer.
  static const Color surfaceHigh = Color(0xFF18191C);

  // ---------------------------------------------------------------------
  // Text and icon tones.
  // ---------------------------------------------------------------------

  /// Primary on-surface text color (pure white for maximum contrast on
  /// AMOLED black).
  static const Color onSurface = Color(0xFFFFFFFF);

  /// Secondary text used for captions and supporting content.
  static const Color onSurfaceMuted = Color(0xFFC9CDD3);

  /// Tertiary text for hints and meta information.
  static const Color onSurfaceTertiary = Color(0xFF8A9099);

  /// Disabled text and icon color.
  static const Color onSurfaceDisabled = Color(0xFF5B6068);

  /// Subtle divider color: 6% white.
  static const Color outline = Color(0x0FFFFFFF);

  // ---------------------------------------------------------------------
  // Interaction — hover, pressed, focus and input fills.
  // ---------------------------------------------------------------------

  /// Hover state fill over glass surfaces: 4% white.
  static const Color hover = Color(0x0AFFFFFF);

  /// Pressed state fill over glass surfaces: 8% white.
  static const Color pressed = Color(0x14FFFFFF);

  /// Focus ring tint derived from the brand primary: 20% primary.
  static const Color focusRing = Color(0x337C4DFF);

  /// Input field fill: 6% white (slightly stronger than cards for legibility).
  static const Color inputFill = Color(0x0FFFFFFF);

  // ---------------------------------------------------------------------
  // Glass — low-opacity whites with baked alpha (4–12% per spec).
  // ---------------------------------------------------------------------

  /// Default glass fill: 6% white.
  static const Color glass = Color(0x0FFFFFFF);

  /// Strong glass fill: 9% white.
  static const Color glassStrong = Color(0x17FFFFFF);

  /// Default glass border: 8% white.
  static const Color border = Color(0x14FFFFFF);

  /// Strong glass border: 12% white.
  static const Color borderStrong = Color(0x1FFFFFFF);

  /// Scrim behind modals: 55% black.
  static const Color scrim = Color(0x8C000000);
}
