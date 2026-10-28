// Opacity tokens for the Forge Design System.
//
// Every alpha value used for fills, borders and scrims must come from this
// scale. Matches the Forge v3 specification (glass 5–10%, borders 6–12%).
library;

/// The shared opacity scale for Forge.
abstract final class AppOpacity {
  AppOpacity._();

  /// Barely visible tint for hover feedback.
  static const double faint = 0.03;

  /// Hover state fill over glass surfaces.
  static const double hover = 0.04;

  /// Pressed state fill over glass surfaces.
  static const double pressed = 0.08;

  /// Subtle white highlight.
  static const double highlight = 0.05;

  /// Lowest glass fill: 4% white.
  static const double glassLow = 0.04;

  /// Default glass fill: 6% white.
  static const double glass = 0.06;

  /// Strongest glass fill: 9% white.
  static const double glassHigh = 0.09;

  /// Faintest glass border: 6% white.
  static const double borderLow = 0.06;

  /// Default glass border: 8% white.
  static const double border = 0.08;

  /// Strongest glass border: 12% white.
  static const double borderHigh = 0.12;

  /// Disabled content opacity.
  static const double disabled = 0.38;

  /// Scrim behind modals and sheets.
  static const double scrim = 0.55;

  /// Fully opaque.
  static const double opaque = 1.0;
}
