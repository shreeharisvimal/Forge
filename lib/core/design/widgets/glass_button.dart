// Glass button for the Forge Design System.
//
// The standard action button. Supports filled, tonal, outlined and ghost
// variants, an optional leading icon, loading state and press haptics.
library;

import 'package:flutter/material.dart';

import '../animations/glass_animated.dart';
import '../colors/forge_colors.dart';
import '../extensions/theme_extensions.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../glass/glass_gradient.dart';
import '../glass/glass_shadow.dart';
import '../tokens/border_width_tokens.dart';
import '../tokens/gradient_presets.dart';
import '../tokens/icon_size_tokens.dart';
import '../tokens/opacity_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/shadow_presets.dart';
import '../tokens/spacing_tokens.dart';
import '../utilities/haptic_helper.dart';
import 'glass_container.dart';
import 'glass_loading.dart';
import 'glass_pressable.dart';

/// The visual variants of [GlassButton].
enum GlassButtonVariant {
  /// Solid brand gradient fill.
  filled,

  /// Translucent brand-tinted fill.
  tonal,

  /// Transparent with a glass border.
  outlined,

  /// Bare text/icon button.
  ghost,
}

/// The size variants of [GlassButton].
enum GlassButtonSize {
  /// Compact.
  small,

  /// Standard.
  medium,

  /// Large.
  large,
}

/// A tappable glass action button.
class GlassButton extends StatelessWidget {
  /// Creates a glass button.
  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = GlassButtonVariant.filled,
    this.size = GlassButtonSize.medium,
    this.expanded = false,
    this.loading = false,
    this.semanticLabel,
    this.tooltip,
    this.haptic = HapticType.medium,
    this.entrance = GlassEntrance.none,
    this.duration,
  });

  /// The button label.
  final String label;

  /// Invoked when the button is pressed. `null` disables the button.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// The visual variant.
  final GlassButtonVariant variant;

  /// The size variant.
  final GlassButtonSize size;

  /// Whether the button fills its available width.
  final bool expanded;

  /// Whether the button shows its loading indicator.
  final bool loading;

  /// Optional semantic label override.
  final String? semanticLabel;

  /// Optional tooltip.
  final String? tooltip;

  /// Haptic fired on press.
  final HapticType haptic;

  /// Optional entrance animation.
  final GlassEntrance entrance;

  /// Entrance animation duration.
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    final (decoration, foreground) = _style(context, enabled);

    final horizontal = switch (size) {
      GlassButtonSize.small => AppSpacing.lg,
      GlassButtonSize.medium => AppSpacing.xl,
      GlassButtonSize.large => AppSpacing.xxl,
    };
    final vertical = switch (size) {
      GlassButtonSize.small => AppSpacing.sm,
      GlassButtonSize.medium => AppSpacing.md,
      GlassButtonSize.large => AppSpacing.lg,
    };
    final iconSize = switch (size) {
      GlassButtonSize.small => AppIconSize.extraSmall,
      GlassButtonSize.medium => AppIconSize.small,
      GlassButtonSize.large => AppIconSize.medium,
    };

    Widget content;
    if (loading) {
      content = GlassLoading(color: foreground, size: iconSize + 4);
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: foreground),
            SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      );
    }

    final radius = BorderRadius.circular(AppRadius.medium);

    Widget button = GlassContainer(
      decoration: decoration,
      borderRadius: radius,
      child: GlassPressable(
        onTap: enabled ? onPressed : null,
        semanticLabel: semanticLabel ?? label,
        tooltip: tooltip,
        haptic: haptic,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
          child: content,
        ),
      ),
    );

    if (expanded) {
      button = SizedBox(width: double.infinity, child: button);
    }

    if (entrance != GlassEntrance.none) {
      button = GlassAnimated(entrance: entrance, duration: duration, child: button);
    }
    return button;
  }

  (GlassDecoration, Color) _style(BuildContext context, bool enabled) {
    final colors = Theme.of(context).forgeColors;
    final radius = BorderRadius.circular(AppRadius.medium);

    final GlassDecoration decoration;
    final Color foreground;
    switch (variant) {
      case GlassButtonVariant.filled:
        decoration = GlassDecoration(
          gradient: GlassGradient(colors: AppGradients.primary),
          borderRadius: radius,
          border: const GlassBorder(width: AppBorderWidth.none),
          shadows: [
            for (final s in AppShadows.glowPrimary)
              GlassShadow(color: s.color, blurRadius: s.blurRadius, offset: s.offset),
          ],
        );
        foreground = colors.onPrimary;
      case GlassButtonVariant.tonal:
        decoration = GlassDecoration(
          color: colors.primary.withValues(alpha: AppOpacity.glassHigh),
          borderRadius: radius,
          border: GlassBorder(color: colors.primary.withValues(alpha: 0.4)),
        );
        foreground = colors.onSurface;
      case GlassButtonVariant.outlined:
        decoration = GlassDecoration(
          color: Colors.transparent,
          borderRadius: radius,
          border:
              const GlassBorder(color: ForgeColors.borderStrong, width: AppBorderWidth.thin),
        );
        foreground = colors.onSurface;
      case GlassButtonVariant.ghost:
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
