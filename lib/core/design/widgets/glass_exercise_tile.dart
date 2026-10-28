// Generic glass exercise tile for the Forge Design System.
//
// A reusable frosted-glass list item tile for exercise library listings.
// Supports custom leading avatars, search query highlighting, metadata text,
// tag chips, favorite star button, and overflow/trailing action menus.
library;

import 'package:flutter/material.dart';

import '../colors/forge_colors.dart';
import '../extensions/theme_extensions.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../theme/color_theme_extension.dart';
import '../tokens/icon_size_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import 'glass_card.dart';
import 'glass_chip.dart';
import 'glass_container.dart';
import 'glass_icon_button.dart';


/// A generic reusable glass tile for displaying an exercise item.
class GlassExerciseTile extends StatelessWidget {
  /// Creates a generic glass exercise tile.
  const GlassExerciseTile({
    super.key,
    required this.title,
    this.subtitle,
    this.equipmentIcon = Icons.fitness_center_rounded,
    this.leading,
    this.tags,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.trailing,
    this.onTap,
    this.query,
    this.padding,
  });

  /// The exercise title name.
  final String title;

  /// Optional subtitle string (e.g. 'Chest · Barbell').
  final String? subtitle;

  /// Icon representing the equipment type.
  final IconData equipmentIcon;

  /// Optional custom leading widget (overrides default avatar icon box).
  final Widget? leading;

  /// Optional list of tag strings.
  final List<String>? tags;

  /// Whether the exercise is marked as favorite.
  final bool isFavorite;

  /// Callback when the favorite toggle icon is pressed.
  final VoidCallback? onFavoriteToggle;

  /// Optional trailing action menu or widget.
  final Widget? trailing;

  /// Callback when the tile is tapped.
  final VoidCallback? onTap;

  /// Search query used for text highlighting.
  final String? query;

  /// Inner padding override.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    final avatarWidget = leading ??
        GlassContainer(
          width: AppSpacing.huge,
          height: AppSpacing.huge,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          decoration: GlassDecoration(
            color: colors.primary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: GlassBorder(color: colors.primary.withValues(alpha: 0.35)),
          ),
          child: Center(
            child: Icon(
              equipmentIcon,
              color: colors.primary,
              size: AppIconSize.medium,
            ),
          ),
        );

    return GlassCard(
      margin: EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
      onTap: onTap,
      decoration: GlassDecoration(
        color: colors.glass,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: const GlassBorder(color: ForgeColors.border),
      ),
      child: Row(
        children: [
          avatarWidget,
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(context, textTheme, colors),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ],
                if (tags != null && tags!.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.xxs),
                  Wrap(
                    spacing: AppSpacing.xxs,
                    runSpacing: AppSpacing.xxs,
                    children: tags!
                        .take(3)
                        .map(
                          (tag) => GlassChip(label: tag),
                        )

                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          if (onFavoriteToggle != null) ...[
            SizedBox(width: AppSpacing.xxs),
            GlassIconButton(
              icon: isFavorite
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              color: isFavorite ? colors.warning : colors.onSurfaceMuted,
              tooltip: isFavorite ? 'Unfavorite' : 'Favorite',
              onPressed: onFavoriteToggle,
              variant: GlassIconButtonVariant.ghost,
              size: AppIconSize.small,
            ),
          ],
          if (trailing != null) trailing!,
        ],
      ),
    );
  }

  Widget _buildTitle(
    BuildContext context,
    TextTheme textTheme,
    ColorThemeExtension colors,
  ) {

    final needle = query?.trim().toLowerCase() ?? '';
    if (needle.isEmpty) {
      return Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lower = title.toLowerCase();
    final index = lower.indexOf(needle);
    if (index < 0) {
      return Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: title.substring(0, index)),
          TextSpan(
            text: title.substring(index, index + needle.length),
            style: TextStyle(
              color: colors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: title.substring(index + needle.length)),
        ],
      ),
      style: textTheme.titleMedium?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
