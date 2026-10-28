// Semantic light-mode palette for the Forge Design System.
//
// The light counterpart of [ForgeColors]. Every surface, text, outline and
// glass tone mirrors the dark scale's visual weight (e.g. 8% glass fill)
// inverted onto near-white surfaces. The brand primary/secondary come from
// the accent palettes, so they are deliberately not defined here.
library;

import 'package:flutter/material.dart';

/// Raw light-mode palette for Forge.
abstract final class ForgeLightColors {
  ForgeLightColors._();

  /// App scaffold background (near-white).
  static const Color background = Color(0xFFF4F4FB);

  /// A slightly deeper tint of the background used to add depth.
  static const Color backgroundRaised = Color(0xFFEBEBF5);

  /// Ambient violet glow used in the shell background (light tint).
  static const Color glowViolet = Color(0xFFB39DDB);

  /// Ambient indigo glow used in the shell background (light tint).
  static const Color glowCyan = Color(0xFF9F7FFF);

  /// Deep violet glow that grounds the background's lower edge.
  static const Color glowVioletDeep = Color(0xFF9575CD);

  /// Default frosted surface for cards, sheets and bars.
  static const Color surface = Color(0xFFFFFFFF);

  /// Surface layer closest to the background.
  static const Color surfaceLow = Color(0xFFF8F8FD);

  /// Elevated surface layer.
  static const Color surfaceHigh = Color(0xFFFFFFFF);

  /// Primary on-surface text color (near-black).
  static const Color onSurface = Color(0xFF17171F);

  /// Muted text used for captions and supporting content.
  static const Color onSurfaceMuted = Color(0xFF5D616B);

  /// Tertiary text for hints and meta information.
  static const Color onSurfaceTertiary = Color(0xFF8A9099);

  /// Disabled text and icon color.
  static const Color onSurfaceDisabled = Color(0xFFB4B9C2);

  /// Subtle outline / divider color: 12% black.
  static const Color outline = Color(0x1F000000);

  /// Hover state fill over glass surfaces: 4% black.
  static const Color hover = Color(0x0A000000);

  /// Pressed state fill over glass surfaces: 8% black.
  static const Color pressed = Color(0x14000000);

  /// Focus ring tint derived from the brand primary: 30% primary.
  static const Color focusRing = Color(0x4D7C4DFF);

  /// Input field fill: 5% black.
  static const Color inputFill = Color(0x0D000000);

  // Glass fills mirror the dark 4–12% alpha scale, inverted onto white.

  /// Default glass fill: 6% black.
  static const Color glass = Color(0x0F000000);

  /// Strong glass fill: 9% black.
  static const Color glassStrong = Color(0x17000000);

  /// Default glass border: 12% black.
  static const Color border = Color(0x1F000000);

  /// Strong glass border: 16% black.
  static const Color borderStrong = Color(0x29000000);

  /// Scrim behind modals: 35% black (lighter than dark mode).
  static const Color scrim = Color(0x59000000);
}
