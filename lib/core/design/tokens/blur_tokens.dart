// Backdrop blur tokens for the Forge Design System.
//
// Every frosted-glass blur in the application must come from this scale.
// The values are sigma passed to an [ImageFilter]; larger means a stronger
// frosted effect.
library;

/// The shared backdrop blur scale for Forge.
abstract final class AppBlur {
  AppBlur._();

  /// No blur.
  static const double none = 0;

  /// Barely perceptible frost.
  static const double subtle = 8;

  /// Light frost for inline surfaces.
  static const double light = 16;

  /// Default frost for cards and bars.
  static const double medium = 24;

  /// Strong frost for sheets.
  static const double strong = 32;

  /// Heavy frost for dialogs and scrims.
  static const double heavy = 48;

  /// Extreme frost for hero moments.
  static const double extreme = 72;
}
