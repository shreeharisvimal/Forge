// Glass chip for the Forge Design System.
//
// A compact tappable label used for filters, tags and quick selections.
// Supports icons, selected state and a delete affordance.
library;

import 'package:flutter/material.dart';

import '../extensions/theme_extensions.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../glass/glass_gradient.dart';
import '../tokens/border_width_tokens.dart';
import '../tokens/gradient_presets.dart';
import '../tokens/icon_size_tokens.dart';
import '../tokens/opacity_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../utilities/haptic_helper.dart';
import 'glass_badge.dart';
import 'glass_container.dart';
import 'glass_pressable.dart';

/// A glass chip.
class GlassChip extends StatelessWidget {
  /// Creates a glass chip.
  const GlassChip({
    super.key,
    required this.label,
    this.icon,
    this.avatar,
    this.selected = false,
    this.onTap,
    this.onDeleted,
    this.semanticLabel,
    this.haptic = HapticType.selection,
  });

  /// The chip label.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional leading avatar.
  final Widget? avatar;

  /// Whether the chip is selected.
  final bool selected;

  /// Invoked when the chip is tapped.
  final VoidCallback? onTap;

  /// Invoked when the delete affordance is pressed.
  final VoidCallback? onDeleted;

  /// Optional semantic label.
  final String? semanticLabel;

  /// Haptic fired on tap.
  final HapticType haptic;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final radius = BorderRadius.circular(AppRadius.extraLarge);

    final decoration = selected
        ? GlassDecoration(
            gradient: GlassGradient(colors: AppGradients.primary),
            borderRadius: radius,
            border: const GlassBorder(width: AppBorderWidth.none),
          )
        : GlassDecoration(
            color: colors.glass,
            borderRadius: radius,
            border: GlassBorder(color: colors.border, width: AppBorderWidth.thin),
          );
    final foreground = selected ? colors.onPrimary : colors.onSurface;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (avatar != null) ...[
          avatar!,
          SizedBox(width: AppSpacing.xs),
        ],
        if (icon != null) ...[
          Icon(icon, size: AppIconSize.extraSmall, color: foreground),
          SizedBox(width: AppSpacing.xs),
        ],
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (onDeleted != null) ...[
          SizedBox(width: AppSpacing.xs),
          InkWell(
            onTap: onDeleted,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxs),
              child: Icon(
                Icons.close_rounded,
                size: AppIconSize.extraSmall,
                color: foreground.withValues(alpha: AppOpacity.disabled),
              ),
            ),
          ),
        ],
      ],
    );

    Widget chip = GlassContainer(
      decoration: decoration,
      borderRadius: radius,
      child: GlassPressable(
        onTap: onTap,
        semanticLabel: semanticLabel ?? label,
        haptic: haptic,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: content,
        ),
      ),
    );

    if (selected) {
      chip = GlassBadge(
        dot: true,
        color: colors.secondary,
        position: GlassBadgePosition.topRight,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: chip,
      );
    }
    return chip;
  }
}
