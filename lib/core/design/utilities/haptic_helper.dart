// Haptic helper for the Forge Design System.
//
// Central access point for haptic feedback so every interaction can fire
// the right feel without knowing the platform implementation details.
library;

import 'package:flutter/services.dart';

/// The distinct haptic feels used across Forge.
enum HapticType {
  /// Light tap feedback.
  light,

  /// Medium tap feedback.
  medium,

  /// Strong confirmation feedback.
  heavy,

  /// Subtle selection tick.
  selection,

  /// Success confirmation.
  success,

  /// Warning feedback.
  warning,
}

/// Helpers for firing haptic feedback.
abstract final class HapticHelper {
  HapticHelper._();

  /// Fires the haptic matching [type].
  static Future<void> fire(HapticType type) async {
    switch (type) {
      case HapticType.light:
        await HapticFeedback.lightImpact();
      case HapticType.medium:
        await HapticFeedback.mediumImpact();
      case HapticType.heavy:
        await HapticFeedback.heavyImpact();
      case HapticType.selection:
        await HapticFeedback.selectionClick();
      case HapticType.success:
        await HapticFeedback.mediumImpact();
      case HapticType.warning:
        await HapticFeedback.heavyImpact();
    }
  }

  /// Light tap feedback.
  static Future<void> light() => fire(HapticType.light);

  /// Medium tap feedback.
  static Future<void> medium() => fire(HapticType.medium);

  /// Heavy confirmation feedback.
  static Future<void> heavy() => fire(HapticType.heavy);

  /// Subtle selection tick.
  static Future<void> selection() => fire(HapticType.selection);

  /// Success confirmation feedback.
  static Future<void> success() => fire(HapticType.success);

  /// Warning feedback.
  static Future<void> warning() => fire(HapticType.warning);
}
