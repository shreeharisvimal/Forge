// Glass list tile for the Forge Design System.
//
// A tappable row with leading, title, subtitle, trailing and optional badge,
// used for navigation and settings rows.
library;

import 'package:flutter/material.dart';

import '../extensions/theme_extensions.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../tokens/icon_size_tokens.dart';
import '../tokens/opacity_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../utilities/haptic_helper.dart';
import 'glass_badge.dart';
import 'glass_container.dart';
import 'glass_pressable.dart';

/// A glass list row.
class GlassListTile extends StatelessWidget {
  /// Creates a glass list tile.
  const GlassListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.dense = false,
    this.badge,
    this.semanticLabel,
    this.haptic = HapticType.selection,
    this.padding,
  });

  /// The primary title.
  final String title;

  /// Optional secondary text.
  final String? subtitle;

  /// Optional leading widget (icon or avatar).
  final Widget? leading;

  /// Optional trailing widget (defaults to a chevron when tappable).
  final Widget? trailing;

  /// Invoked when the tile is tapped.
  final VoidCallback? onTap;

  /// Whether the tile is highlighted as selected.
  final bool selected;

  /// Whether to use compact vertical padding.
  final bool dense;

  /// Optional badge value on the trailing edge.
  final Object? badge;

  /// Optional semantic label.
  final String? semanticLabel;

  /// Haptic fired on tap.
  final HapticType haptic;

  /// Inner padding override.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppRadius.small);

    final row = Row(
      children: [
        if (leading != null) ...[
          leading!,
          SizedBox(width: AppSpacing.lg),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (badge != null) ...[
          SizedBox(width: AppSpacing.sm),
          GlassBadge(value: badge),
        ],
        if (trailing != null) ...[
          SizedBox(width: AppSpacing.sm),
          trailing!,
        ] else if (onTap != null) ...[
          SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.chevron_right_rounded,
            size: AppIconSize.medium,
            color: colors.onSurfaceMuted.withValues(alpha: AppOpacity.disabled),
          ),
        ],
      ],
    );

    Widget tile = GlassContainer(
      decoration: GlassDecoration(
        color: selected ? colors.primary.withValues(alpha: 0.18) : colors.glass,
        borderRadius: radius,
        border: selected
            ? GlassBorder(color: colors.primary.withValues(alpha: 0.5))
            : GlassBorder(color: colors.glassStrong),
      ),
      borderRadius: radius,
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: dense ? AppSpacing.md : AppSpacing.lg,
          ),
      child: row,
    );

    if (onTap != null) {
      tile = GlassPressable(
        onTap: onTap,
        semanticLabel: semanticLabel ?? title,
        haptic: haptic,
        borderRadius: radius,
        child: tile,
      );
    }
    return tile;
  }
}
