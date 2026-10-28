// Glass icon button for the Forge Design System.
//
// A circular glass button for icon-only actions with optional badge.
library;

import 'package:flutter/material.dart';

import '../extensions/theme_extensions.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../glass/glass_gradient.dart';
import '../glass/glass_shadow.dart';
import '../tokens/border_width_tokens.dart';
import '../tokens/icon_size_tokens.dart';
import '../tokens/opacity_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/shadow_presets.dart';
import '../tokens/spacing_tokens.dart';
import '../utilities/haptic_helper.dart';
import 'glass_badge.dart';
import 'glass_container.dart';
import 'glass_pressable.dart';

/// The visual variants of [GlassIconButton].
enum GlassIconButtonVariant {
  /// Frosted glass fill.
  glass,

  /// Solid brand fill.
  filled,

  /// Transparent with a border.
  outlined,

  /// Bare icon.
  ghost,
}

/// A circular glass icon button.
class GlassIconButton extends StatelessWidget {
  /// Creates a glass icon button.
  const GlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = GlassIconButtonVariant.glass,
    this.size = AppIconSize.medium,
    this.color,
    this.tooltip,
    this.semanticLabel,
    this.haptic = HapticType.selection,
    this.badge,
  });

  /// The icon to display.
  final IconData icon;

  /// Invoked when pressed. `null` disables the button.
  final VoidCallback? onPressed;

  /// The visual variant.
  final GlassIconButtonVariant variant;

  /// The icon size.
  final double size;

  /// Optional icon color override.
  final Color? color;

  /// Optional tooltip.
  final String? tooltip;

  /// Optional semantic label.
  final String? semanticLabel;

  /// Haptic fired on press.
  final HapticType haptic;

  /// Optional badge value rendered on the corner.
  final Object? badge;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final padding = AppSpacing.sm;
    final diameter = size + padding * 2 + AppSpacing.lg;

    final (decoration, iconColor) = _style(context, enabled);
    final radius = BorderRadius.circular(AppRadius.extraLarge);

    Widget button = GlassContainer(
      decoration: decoration,
      borderRadius: radius,
      width: diameter,
      height: diameter,
      child: GlassPressable(
        onTap: onPressed,
        semanticLabel: semanticLabel,
        tooltip: tooltip,
        haptic: haptic,
        borderRadius: radius,
        child: Center(
          child: Icon(
            icon,
            size: size,
            color: color ?? iconColor,
          ),
        ),
      ),
    );

    if (badge != null) {
      button = GlassBadge(
        value: badge,
        position: GlassBadgePosition.topRight,
        child: button,
      );
    }
    return button;
  }

  (GlassDecoration, Color) _style(BuildContext context, bool enabled) {
    final colors = Theme.of(context).forgeColors;
    final radius = BorderRadius.circular(AppRadius.extraLarge);

    final GlassDecoration decoration;
    final Color foreground;
    switch (variant) {
      case GlassIconButtonVariant.glass:
        decoration = GlassDecoration(
          color: colors.glass,
          borderRadius: radius,
          border: GlassBorder(color: colors.border, width: AppBorderWidth.thin),
          shadows: AppShadows.soft.map((s) => GlassShadow(color: s.color, blurRadius: s.blurRadius, offset: s.offset)).toList(),
        );
        foreground = colors.onSurface;
      case GlassIconButtonVariant.filled:
        decoration = GlassDecoration(
          gradient: GlassGradient(colors: [colors.primary, colors.primary]),
          borderRadius: radius,
          border: const GlassBorder(width: AppBorderWidth.none),
        );
        foreground = colors.onPrimary;
      case GlassIconButtonVariant.outlined:
        decoration = GlassDecoration(
          color: Colors.transparent,
          borderRadius: radius,
          border: GlassBorder(color: colors.borderStrong, width: AppBorderWidth.thin),
        );
        foreground = colors.onSurface;
      case GlassIconButtonVariant.ghost:
        decoration = GlassDecoration(
          color: Colors.transparent,
          borderRadius: radius,
          border: const GlassBorder(width: AppBorderWidth.none),
        );
        foreground = colors.onSurface;
    }

    return (
      decoration,
      enabled ? foreground : foreground.withValues(alpha: AppOpacity.disabled),
    );
  }
}
