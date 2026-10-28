// Glass badge for the Forge Design System.
//
// A small notification pill or dot that attaches to a child's corner or
// stands alone.
library;

import 'package:flutter/material.dart';

import '../extensions/theme_extensions.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../tokens/border_width_tokens.dart';
import '../tokens/icon_size_tokens.dart';
import '../tokens/opacity_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import 'glass_container.dart';

/// The corner a [GlassBadge] attaches to.
enum GlassBadgePosition {
  /// Top-right corner.
  topRight,

  /// Top-left corner.
  topLeft,

  /// Bottom-right corner.
  bottomRight,

  /// Bottom-left corner.
  bottomLeft,
}

/// A glass notification badge.
class GlassBadge extends StatelessWidget {
  /// Creates a badge.
  const GlassBadge({
    super.key,
    this.value,
    this.dot = false,
    this.color,
    this.position = GlassBadgePosition.topRight,
    this.margin = const EdgeInsets.all(0),
    this.child,
    this.max = 99,
    this.semanticLabel,
  });

  /// The badge value (rendered as text). Ignored when [dot] is true.
  final Object? value;

  /// Whether to render a plain indicator dot.
  final bool dot;

  /// Badge color override.
  final Color? color;

  /// The corner the badge attaches to.
  final GlassBadgePosition position;

  /// Extra offset applied to the badge.
  final EdgeInsets margin;

  /// The child the badge attaches to. When `null` the badge stands alone.
  final Widget? child;

  /// Largest numeric value rendered verbatim; larger values become `max+`.
  final int max;

  /// Optional semantic label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final badgeColor = color ?? colors.danger;

    final Widget badge = dot
        ? Container(
            width: AppIconSize.extraSmall,
            height: AppIconSize.extraSmall,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: AppOpacity.scrim),
                  blurRadius: 6,
                ),
              ],
            ),
          )
        : GlassContainer(
            decoration: GlassDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(AppRadius.extraLarge),
              border: const GlassBorder(width: AppBorderWidth.none),
            ),
            borderRadius: BorderRadius.circular(AppRadius.extraLarge),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            child: Text(
              _label(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          );

    if (child == null) {
      return Semantics(
        label: semanticLabel ?? 'Badge',
        child: badge,
      );
    }

    return Semantics(
      label: semanticLabel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child!,
          Positioned(
            top: position == GlassBadgePosition.topLeft ||
                    position == GlassBadgePosition.topRight
                ? margin.top
                : null,
            bottom: position == GlassBadgePosition.bottomLeft ||
                    position == GlassBadgePosition.bottomRight
                ? margin.bottom
                : null,
            left: position == GlassBadgePosition.bottomLeft ||
                    position == GlassBadgePosition.topLeft
                ? margin.left
                : null,
            right: position == GlassBadgePosition.bottomRight ||
                    position == GlassBadgePosition.topRight
                ? margin.right
                : null,
            child: badge,
          ),
        ],
      ),
    );
  }

  String _label() {
    final value = this.value;
    if (value is num && value.toInt() > max) return '$max+';
    return '$value';
  }
}
