// Animation duration tokens for the Forge Design System.
//
// Every animation duration in the application must come from this scale.
// Keeping a small set of named durations guarantees consistent motion.
library;

/// The shared animation duration scale for Forge.
abstract final class AppDuration {
  AppDuration._();

  /// Instant, non-animated transitions.
  static const Duration instant = Duration.zero;

  /// Sub-frame feedback (press states).
  static const Duration micro = Duration(milliseconds: 60);

  /// Fast feedback such as icon swaps.
  static const Duration fast = Duration(milliseconds: 120);

  /// Quick transitions such as toggle slides.
  static const Duration quick = Duration(milliseconds: 180);

  /// Short transitions such as card focus changes.
  static const Duration short = Duration(milliseconds: 240);

  /// Standard transitions.
  static const Duration medium = Duration(milliseconds: 320);

  /// Emphasized transitions such as sheet entrances.
  static const Duration long = Duration(milliseconds: 480);

  /// Slow, deliberate transitions.
  static const Duration slow = Duration(milliseconds: 640);

  /// Default page transition duration.
  static const Duration page = Duration(milliseconds: 400);

  /// One full sweep of the ambient background drift.
  static const Duration background = Duration(seconds: 18);
}
