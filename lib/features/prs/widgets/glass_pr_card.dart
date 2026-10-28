// Glass PR card for the Forge application.
//
// A record entry: the exercise, the record type, the new value, the value it
// beat (with the signed improvement) and the date it was set. Used in the
// summary's records section and the PR history.
library;

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';
import '../../workout_session/domain/session_formatters.dart';
import '../data/pr_event.dart';
import 'pr_widget_utils.dart';

/// A glass card for a single personal-record event.
class GlassPrCard extends StatelessWidget {
  /// Creates a PR card.
  const GlassPrCard({
    super.key,
    required this.event,
    required this.unit,
    this.onTap,
    this.highlight = false,
  });

  /// The record to display.
  final PrEvent event;

  /// The weight unit for display.
  final SessionWeightUnit unit;

  /// Invoked when the card is tapped.
  final VoidCallback? onTap;

  /// Whether to emphasize the card as freshly earned.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final type = event.prType;
    final accent = highlight ? colors.success : colors.primary;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: GlassDecoration(
        color: accent.withValues(alpha: highlight ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: GlassBorder(color: accent.withValues(alpha: highlight ? 0.45 : 0.25)),
      ),
      onTap: onTap,
      child: Row(
        children: [
          GlassContainer(
            width: AppSpacing.huge,
            height: AppSpacing.huge,
            borderRadius: BorderRadius.circular(AppRadius.extraLarge),
            decoration: GlassDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.extraLarge),
              border: const GlassBorder(),
            ),
            child: Center(
              child: Icon(prTypeIcon(type), size: AppIconSize.small, color: accent),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        event.exerciseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      type.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceMuted,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xxs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        prValueLabel(type, event.value, unit),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    if (event.previousValue > 0 && event.difference > 0) ...[
                      SizedBox(width: AppSpacing.sm),
                      Icon(Icons.arrow_upward_rounded,
                          size: AppIconSize.extraSmall, color: colors.success),
                      Text(
                        '+${prValueLabel(type, event.difference, unit)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.success,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            prRelativeDate(event.date),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
          ),
        ],
      ),
    );
  }
}
