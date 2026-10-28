// Spacing scale tokens for the Forge Design System.
//
// Every layout gap in the application must come from this scale. The grid
// is 8-point aligned and matches the Forge v3 specification (4, 8, 12, 16,
// 20, 24, 32, 40, 48). Never hardcode a spacing value.
library;

import 'package:flutter/material.dart';

/// The shared spacing scale for Forge.
///
/// Exposes the full 8-point aligned grid as named constants so widget code
/// reads like `AppSpacing.lg` instead of a raw number.
abstract final class AppSpacing {
  AppSpacing._();

  /// 4 dp — smallest hairline gap.
  static const double xxs = 4;

  /// 4 dp.
  static const double xs = 4;

  /// 8 dp.
  static const double sm = 8;

  /// 12 dp.
  static const double md = 12;

  /// 16 dp — default content inset.
  static const double lg = 16;

  /// 20 dp.
  static const double xl = 20;

  /// 24 dp — section spacing.
  static const double xxl = 24;

  /// 32 dp — large section spacing.
  static const double xxxl = 32;

  /// 40 dp.
  static const double huge = 40;

  /// 48 dp — largest layout gap.
  static const double giant = 48;

  /// The smallest tappable target dimension (accessibility).
  static const double touchTarget = 48;

  /// The largest constrained content width for wide screens.
  static const double maxContentWidth = 840;
}

/// Extensions that turn raw spacing values into [EdgeInsets].
///
/// Reads naturally as `AppSpacing.lg.h` or `AppSpacing.md.all`.
extension SpacingValueX on double {
  /// An [EdgeInsets] with this value on every side.
  EdgeInsets get all => EdgeInsets.all(this);

  /// An [EdgeInsets] with this value on the horizontal axis.
  EdgeInsets get h => EdgeInsets.symmetric(horizontal: this);

  /// An [EdgeInsets] with this value on the vertical axis.
  EdgeInsets get v => EdgeInsets.symmetric(vertical: this);

  /// An [EdgeInsets] with this value on the left side only.
  EdgeInsets get left => EdgeInsets.only(left: this);

  /// An [EdgeInsets] with this value on the right side only.
  EdgeInsets get right => EdgeInsets.only(right: this);

  /// An [EdgeInsets] with this value on the top side only.
  EdgeInsets get top => EdgeInsets.only(top: this);

  /// An [EdgeInsets] with this value on the bottom side only.
  EdgeInsets get bottom => EdgeInsets.only(bottom: this);

  /// An [EdgeInsets] combining this value on both horizontal sides.
  EdgeInsets get horizontal => EdgeInsets.symmetric(horizontal: this);

  /// An [EdgeInsets] combining this value on both vertical sides.
  EdgeInsets get vertical => EdgeInsets.symmetric(vertical: this);
}
