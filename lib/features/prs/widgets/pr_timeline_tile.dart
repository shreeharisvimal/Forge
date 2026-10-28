// PR timeline tile for the Forge application.
//
// One row of a chronological PR history: a colored node with a connector
// line, the record type and exercise, the value and the date. Composes into
// a full timeline when rendered as a vertical list.
library;

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';
import '../../workout_session/domain/session_formatters.dart';
import '../data/pr_event.dart';
import '../domain/pr_types.dart';
import 'glass_pr_badge.dart';
import 'pr_widget_utils.dart';

/// A vertical timeline row for one [PrEvent].
class PrTimelineTile extends StatelessWidget {
  /// Creates a timeline row.
  const PrTimelineTile({
    super.key,
    required this.event,
    required this.unit,
    this.isFirst = false,
    this.isLast = false,
    this.highlight = false,
  });

  /// The record to display.
  final PrEvent event;

  /// The weight unit for display.
  final SessionWeightUnit unit;

  /// Whether this row is the first in the timeline (no upper line).
  final bool isFirst;

  /// Whether this row is the last in the timeline (no lower line).
  final bool isLast;

  /// Whether to emphasize the row as freshly earned.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final type = event.prType;
    final accent = highlight ? colors.success : colors.primary;
    final lineColor = colors.outline;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: AppSpacing.xl,
            child: Column(
              children: [
                SizedBox(height: isFirst ? AppSpacing.lg : 0),
                Container(
                  width: isFirst ? 2 : 2,
                  height: isFirst ? 0 : AppSpacing.md,
                  color: lineColor,
                ),
                Container(
                  width: AppSpacing.md,
                  height: AppSpacing.md,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 2,
                  height: isLast ? 0 : null,
                  color: lineColor,
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: isFirst ? AppSpacing.sm : 0,
                bottom: isLast ? 0 : AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${event.exerciseName} · ${type.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      if (highlight)
                        GlassPrBadge(status: PrStatus.newPr, compact: true),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    event.previousValue > 0
                        ? '${prValueLabel(type, event.value, unit)} · '
                            '+${prValueLabel(type, event.difference, unit)}'
                        : '${prValueLabel(type, event.value, unit)} · First ever',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    prRelativeDate(event.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
