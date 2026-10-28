// Icon size tokens for the Forge Design System.
//
// Every icon size in the application must come from this scale. The
// default is 24 dp per the Forge v2 iconography spec.
library;

/// The shared icon size scale for Forge.
abstract final class AppIconSize {
  AppIconSize._();

  /// 16 dp — inline affordances.
  static const double extraSmall = 16;

  /// 20 dp — small control icons.
  static const double small = 20;

  /// 24 dp — default icon size.
  static const double medium = 24;

  /// 28 dp — prominent control icons.
  static const double large = 28;

  /// 32 dp — feature icons.
  static const double extraLarge = 32;

  /// 40 dp — large feature icons.
  static const double doubleExtraLarge = 40;

  /// 48 dp — empty-state hero icons.
  static const double tripleExtraLarge = 48;
}
