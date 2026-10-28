// Shadow preset tokens for the Forge Design System.
//
// Layered shadows give glass surfaces their floating, ambient quality.
// Every elevation shadow in the application must come from these presets.
library;

import 'package:flutter/material.dart';

/// Shared shadow presets for Forge.
abstract final class AppShadows {
  AppShadows._();

  /// Barely-there shadow for raised cards.
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, 3),
    ),
  ];

  /// Shadow for standard cards.
  static const List<BoxShadow> raised = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  /// Shadow for floating surfaces (nav bar, sheets).
  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  /// Shadow for modals and dialogs.
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 40,
      offset: Offset(0, 20),
    ),
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 14,
      offset: Offset(0, 6),
    ),
  ];

  /// Focus ring glow built from the primary color.
  static List<BoxShadow> focus(Color primary, {double intensity = 0.22}) {
    return [
      BoxShadow(
        color: primary.withValues(alpha: intensity),
        blurRadius: 14,
        offset: const Offset(0, 0),
      ),
    ];
  }

  /// Primary-colored ambient glow for emphasis.
  static const List<BoxShadow> glowPrimary = [
    BoxShadow(
      color: Color(0x307C4DFF),
      blurRadius: 22,
      offset: Offset(0, 5),
    ),
  ];

  /// Secondary-colored ambient glow.
  static const List<BoxShadow> glowSecondary = [
    BoxShadow(
      color: Color(0x26B388FF),
      blurRadius: 22,
      offset: Offset(0, 5),
    ),
  ];

  /// Success-colored ambient glow.
  static const List<BoxShadow> glowSuccess = [
    BoxShadow(
      color: Color(0x2922C55E),
      blurRadius: 22,
      offset: Offset(0, 5),
    ),
  ];

  /// Danger-colored ambient glow.
  static const List<BoxShadow> glowDanger = [
    BoxShadow(
      color: Color(0x29EF4444),
      blurRadius: 22,
      offset: Offset(0, 5),
    ),
  ];

  /// A colored glow built from any brand color.
  static List<BoxShadow> glow(Color color, {double intensity = 0.25}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: intensity),
        blurRadius: 22,
        offset: const Offset(0, 5),
      ),
    ];
  }
}
