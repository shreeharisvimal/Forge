// Generic glass calendar cell for the Forge Design System.
//
// A reusable frosted-glass calendar day cell widget. Pure presentation: accepts
// primitive date state and marker widgets, rendering a styled glass container.
library;

import 'package:flutter/material.dart';

import '../animations/glass_hero.dart';
import '../extensions/theme_extensions.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../glass/glass_gradient.dart';
import '../tokens/border_width_tokens.dart';
import '../tokens/duration_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import 'glass_container.dart';

/// A generic reusable frosted-glass calendar day cell widget.
class GlassCalendarCell extends StatelessWidget {
  /// Creates a generic glass calendar day cell.
  const GlassCalendarCell({
    super.key,
    required this.day,
    this.isSelected = false,
    this.isToday = false,
    this.isOutside = false,
    this.isFuture = false,
    this.isPast = false,
    this.isDisabled = false,
    this.markers = const [],
    this.onTap,
    this.heroTag,
  });

  /// The day represented by this cell.
  final DateTime day;

  /// Whether the day is currently selected.
  final bool isSelected;

  /// Whether the day is today.
  final bool isToday;

  /// Whether the day belongs to an adjacent month.
  final bool isOutside;

  /// Whether the day lies in the future.
  final bool isFuture;

  /// Whether the day lies in the past.
  final bool isPast;

  /// Whether the cell interaction is disabled.
  final bool isDisabled;

  /// List of marker widgets (e.g. badges, dots) displayed under the day number.
  final List<Widget> markers;

  /// Callback when the cell is tapped.
  final VoidCallback? onTap;

  /// Optional Hero tag for transition animation when selected.
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppRadius.medium);

    final Widget surface;
    if (isSelected) {
      surface = GlassContainer(
        decoration: GlassDecoration(
          gradient: GlassGradient(
            colors: [colors.primary, colors.primary.withValues(alpha: 0.8)],
          ),
          borderRadius: radius,
          border: const GlassBorder(width: AppBorderWidth.none),
        ),
        borderRadius: radius,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.xxs,
        ),
        child: _cellBody(
          context,
          dayColor: colors.onPrimary,
          textTheme: textTheme,
        ),
      );
    } else if (isToday) {
      surface = GlassContainer(
        decoration: GlassDecoration(
          color: colors.glassStrong,
          borderRadius: radius,
          border: GlassBorder(color: colors.primary, width: AppBorderWidth.thin),
        ),
        borderRadius: radius,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.xxs,
        ),
        child: _cellBody(
          context,
          dayColor: colors.primary,
          textTheme: textTheme,
        ),
      );
    } else if (isFuture || isDisabled) {
      surface = GlassContainer(
        decoration: GlassDecoration(
          color: colors.surface.withValues(alpha: 0.2),
          borderRadius: radius,
          border: const GlassBorder(width: AppBorderWidth.none),
        ),
        borderRadius: radius,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.xxs,
        ),
        child: _cellBody(
          context,
          dayColor: colors.onSurfaceMuted,
          textTheme: textTheme,
        ),
      );
    } else {
      surface = GlassContainer(
        decoration: GlassDecoration(
          color: colors.surface.withValues(alpha: 0.4),
          borderRadius: radius,
          border: const GlassBorder(width: AppBorderWidth.none),
        ),
        borderRadius: radius,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.xxs,
        ),
        child: _cellBody(
          context,
          dayColor: colors.onSurface,
          textTheme: textTheme,
        ),
      );
    }

    final opacity = isDisabled
        ? 0.3
        : (isOutside || isFuture) && !isSelected
            ? 0.45
            : 1.0;

    Widget cell = AnimatedContainer(
      duration: AppDuration.short,
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxs,
        horizontal: AppSpacing.xxs,
      ),
      child: Opacity(opacity: opacity, child: surface),
    );

    if (onTap != null && !isDisabled) {
      cell = GestureDetector(
        onTap: onTap,
        child: cell,
      );
    }

    if (heroTag != null && isSelected) {
      cell = GlassHero(
        tag: heroTag!,
        child: cell,
      );
    }

    return cell;
  }

  Widget _cellBody(
    BuildContext context, {
    required Color dayColor,
    required TextTheme textTheme,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${day.day}',
          style: textTheme.titleMedium?.copyWith(
            color: dayColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (markers.isNotEmpty) ...[
          SizedBox(height: AppSpacing.xxs),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: markers,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
