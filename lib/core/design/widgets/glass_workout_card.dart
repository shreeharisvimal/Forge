// Generic glass workout card for the Forge Design System.
//
// A reusable frosted-glass workout / split-day card displaying workout title,
// muscle focus, exercise list summary, accent icons, badges, and action buttons.
library;

import 'package:flutter/material.dart';

import '../extensions/theme_extensions.dart';
import '../colors/forge_colors.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../tokens/icon_size_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import 'glass_card.dart';
import 'glass_container.dart';

/// A generic reusable glass card displaying workout or split information.
class GlassWorkoutCard extends StatelessWidget {
  /// Creates a generic glass workout card.
  const GlassWorkoutCard({
    super.key,
    required this.title,
    this.subtitle,
    this.focus,
    this.exerciseCount,
    this.exerciseNames,
    this.accentColor,
    this.icon = Icons.fitness_center_rounded,
    this.statusBadge,
    this.actionButton,
    this.onTap,
    this.padding,
    this.margin,
  });

  /// The main workout or split title (e.g. 'Push Day A' or 'Upper Body').
  final String title;

  /// Optional subtitle (e.g. split name 'PPL Split').
  final String? subtitle;

  /// Optional focus area description (e.g. 'Chest · Shoulders · Triceps').
  final String? focus;

  /// Optional exercise count.
  final int? exerciseCount;

  /// Optional preview list of exercise names.
  final List<String>? exerciseNames;

  /// Optional primary accent color for icon container and header text.
  final Color? accentColor;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional status badge widget (e.g. 'Done' or 'Scheduled').
  final Widget? statusBadge;

  /// Optional action button widget (e.g. 'Start workout' button).
  final Widget? actionButton;

  /// Optional tap callback for the card.
  final VoidCallback? onTap;

  /// Custom padding inside the card.
  final EdgeInsetsGeometry? padding;

  /// Custom outer margin.
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    final effectiveAccent = accentColor ?? colors.primary;

    final previewList = exerciseNames != null
        ? exerciseNames!.take(3).toList()
        : const <String>[];
    final totalExercises = exerciseCount ?? exerciseNames?.length ?? 0;
    final remainingCount = totalExercises - previewList.length;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              GlassContainer(
                width: AppSpacing.huge,
                height: AppSpacing.huge,
                borderRadius: BorderRadius.circular(AppRadius.large),
                decoration: GlassDecoration(
                  color: effectiveAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: AppIconSize.large,
                    color: effectiveAccent,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.lg),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle != null) ...[
                    Text(
                      subtitle!,
                      style: textTheme.labelLarge?.copyWith(
                        color: effectiveAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                  ],
                  Text(
                    title,
                    style: textTheme.headlineSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (statusBadge != null) statusBadge!,
          ],
        ),
        if (focus != null && focus!.isNotEmpty) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            focus!,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
        ],
        if (totalExercises > 0 || previewList.isNotEmpty) ...[
          SizedBox(height: AppSpacing.lg),
          Text(
            '$totalExercises exercises',
            style: textTheme.labelLarge?.copyWith(color: colors.onSurface),
          ),
          if (previewList.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              remainingCount > 0
                  ? '${previewList.join(' · ')}, and $remainingCount more'
                  : previewList.join(' · '),
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ],
        ],
        if (actionButton != null) ...[
          SizedBox(height: AppSpacing.lg),
          actionButton!,
        ],
      ],
    );

    return GlassCard(
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? AppSpacing.lg.all,
      onTap: onTap,
      decoration: GlassDecoration(
        color: colors.glass,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: const GlassBorder(color: ForgeColors.border),
      ),
      child: content,
    );
  }
}
