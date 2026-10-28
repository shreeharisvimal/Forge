// Global animation switch for the Forge design system.
//
// Decorative and feedback animations run by default so production stays
// beautiful. Widget tests can disable them so tests are deterministic and
// fast: loading indicators freeze on a static frame, indeterminate progress
// bars stop, the ambient background stops drifting and page transitions
// complete instantly.
//
// Detection is automatic — `flutter test` sets the `FLUTTER_TEST` variable —
// and tests can still force the mode with [AnimationConfig.disable].
library;

import 'dart:io' show Platform;

/// Whether Forge animations are currently disabled (test / reduced-motion
/// mode). Read by every indefinite animation so it can render a static frame
/// instead of a repeating controller.
abstract final class AnimationConfig {
  AnimationConfig._();

  static bool _disabled = _detect();

  static bool _detect() {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  /// Whether decorative animations are disabled.
  static bool get isDisabled => _disabled;

  /// Disables decorative animations (used by widget tests).
  static void disable() => _disabled = true;

  /// Re-enables decorative animations.
  static void enable() => _disabled = false;
}
