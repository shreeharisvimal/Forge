// Border width tokens for the Forge Design System.
//
// Every border width in the application must come from this scale.
library;

/// The shared border width scale for Forge.
abstract final class AppBorderWidth {
  AppBorderWidth._();

  /// No border.
  static const double none = 0;

  /// Hairline — used for the finest separation lines.
  static const double hairline = 0.5;

  /// Thin — default glass borders.
  static const double thin = 1;

  /// Regular — emphasized borders.
  static const double regular = 1.5;

  /// Thick — active / focused borders.
  static const double thick = 2;

  /// Heavy — prominent accents.
  static const double heavy = 3;
}
