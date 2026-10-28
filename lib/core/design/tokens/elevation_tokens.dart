// Elevation tokens for the Forge Design System.
//
// Elevation values describe how far a surface floats above its backdrop.
// Combined with the blur and shadow tokens they drive the layered glass
// look. Never hardcode an elevation value.
library;

/// The shared elevation scale for Forge.
abstract final class AppElevation {
  AppElevation._();

  /// Surfaces flush with their backdrop.
  static const double none = 0;

  /// Barely lifted surfaces (dividers, input fills).
  static const double flat = 1;

  /// Raised cards and tiles.
  static const double raised = 2;

  /// Overlaying content such as tooltips and badges.
  static const double overlaying = 4;

  /// Floating surfaces such as the FAB and navigation bar.
  static const double floating = 6;

  /// Modals, sheets and dialogs.
  static const double modal = 12;
}
