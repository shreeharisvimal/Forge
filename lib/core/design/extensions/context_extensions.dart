// BuildContext extensions for the Forge Design System.
//
// Ergonomics for the most common design-system lookups and helpers so
// widget code reads as `context.forgeColors` and `context.showGlassSheet()`.
library;

import 'package:flutter/material.dart';

import '../theme/animation_theme_extension.dart';
import '../theme/color_theme_extension.dart';
import '../theme/glass_theme_extension.dart';
import '../theme/spacing_theme_extension.dart';
import '../theme/typography_theme_extension.dart';
import '../utilities/haptic_helper.dart';
import '../utilities/responsive_helper.dart';
import '../utilities/screen_size_helper.dart';
import '../widgets/glass_bottom_sheet.dart';
import '../widgets/glass_dialog.dart';
import 'theme_extensions.dart';

/// Convenience accessors on [BuildContext].
extension ForgeContextX on BuildContext {
  /// The glass parameters for the current theme.
  GlassThemeExtension get glass => Theme.of(this).glass;

  /// The semantic color palette for the current theme.
  ColorThemeExtension get forgeColors => Theme.of(this).forgeColors;

  /// The spacing scale for the current theme.
  SpacingThemeExtension get spacing => Theme.of(this).spacing;

  /// The animation durations and curves for the current theme.
  AnimationThemeExtension get anim => Theme.of(this).anim;

  /// The shared typography for the current theme.
  TypographyThemeExtension get forgeTypography => Theme.of(this).forgeTypography;

  // ---------------------------------------------------------------------
  // Responsive.
  // ---------------------------------------------------------------------

  /// Whether the layout is phone-sized.
  bool get isCompact => Responsive.isCompact(this);

  /// Whether the layout is tablet-sized or larger.
  bool get isTablet => ScreenSize.isTablet(this);

  /// Whether the layout is desktop-sized.
  bool get isExpanded => Responsive.isExpanded(this);

  /// The current screen width.
  double get screenWidth => ScreenSize.widthOf(this);

  /// The current screen height.
  double get screenHeight => ScreenSize.heightOf(this);

  /// A width-capped content width for adaptive layouts.
  double get maxContentWidth => ScreenSize.maxContentWidth(this);

  /// The current safe-area padding.
  EdgeInsets get safePadding => MediaQuery.paddingOf(this);

  // ---------------------------------------------------------------------
  // Haptics.
  // ---------------------------------------------------------------------

  /// Fires light haptic feedback.
  Future<void> hapticLight() => HapticHelper.light();

  /// Fires medium haptic feedback.
  Future<void> hapticMedium() => HapticHelper.medium();

  /// Fires heavy haptic feedback.
  Future<void> hapticHeavy() => HapticHelper.heavy();

  /// Fires selection haptic feedback.
  Future<void> hapticSelection() => HapticHelper.selection();

  /// Fires success haptic feedback.
  Future<void> hapticSuccess() => HapticHelper.success();

  /// Fires warning haptic feedback.
  Future<void> hapticWarning() => HapticHelper.warning();

  // ---------------------------------------------------------------------
  // Overlays.
  // ---------------------------------------------------------------------

  /// Presents a [GlassBottomSheet].
  Future<T?> showGlassBottomSheet<T>({
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool useSafeArea = true,
    bool showDragHandle = true,
    bool enableDrag = true,
    bool snap = false,
    double initialChildSize = 0.6,
    double minChildSize = 0.3,
    double maxChildSize = 0.95,
  }) {
    return GlassBottomSheet.show<T>(
      this,
      builder: builder,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      showDragHandle: showDragHandle,
      enableDrag: enableDrag,
      snap: snap,
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
    );
  }

  /// Presents a [GlassDialog].
  Future<T?> showGlassDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return GlassDialog.show<T>(
      this,
      builder: builder,
      barrierDismissible: barrierDismissible,
    );
  }
}
