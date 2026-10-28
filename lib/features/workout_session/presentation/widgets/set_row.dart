// Set row widget for the active workout.
//
// One editable row per performed set: complete toggle on the left, the
// weight x reps summary in the middle (tap to edit), and duplicate/delete
// actions on the right. Warm-up sets are labelled and tinted differently.
library;

import 'package:flutter/material.dart';

import '../../../../core/design/forge_design.dart';
import '../../../../models/workout_set.dart';
import '../../domain/session_formatters.dart';

/// A single set row inside an exercise card.
class SetRow extends StatelessWidget {
  /// Creates a set row.
  const SetRow({
    super.key,
    required this.index,
    required this.set,
    required this.unit,
    required this.onCompleteToggle,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  /// The 1-based position within the exercise.
  final int index;

  /// The set to render.
  final WorkoutSet set;

  /// The weight unit for display.
  final SessionWeightUnit unit;

  /// Invoked when the completion toggle is pressed.
  final VoidCallback onCompleteToggle;

  /// Invoked when the row's summary is tapped.
  final VoidCallback onEdit;

  /// Invoked when the duplicate action is pressed.
  final VoidCallback onDuplicate;

  /// Invoked when the delete action is pressed.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    final accent = set.completed ? colors.success : colors.primary;

    return GlassContainer(
      decoration: GlassDecoration(
        color: set.completed
            ? colors.success.withValues(alpha: 0.08)
            : colors.glass,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: GlassBorder(
          color: set.completed
              ? colors.success.withValues(alpha: 0.4)
              : Colors.white,
        ),
      ),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          _CompleteToggle(completed: set.completed, onTap: onCompleteToggle),
          SizedBox(width: AppSpacing.sm),
          _SetNumber(index: index, isWarmup: set.isWarmup, color: accent),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: GlassPressable(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${SessionFormatters.weight(set.weight, unit)} × ${set.reps}',
                      style: textTheme.bodyLarge?.copyWith(
                        color: set.completed
                            ? colors.onSurfaceMuted
                            : colors.onSurface,
                        fontWeight: FontWeight.w600,
                        decoration:
                            set.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (set.rpe != null || set.tempo != null)
                      Text(
                        [
                          if (set.rpe != null) 'RPE ${set.rpe}',
                          if (set.tempo != null) 'tempo ${set.tempo}',
                        ].join(' · '),
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          GlassIconButton(
            icon: Icons.copy_rounded,
            variant: GlassIconButtonVariant.ghost,
            size: AppIconSize.extraSmall,
            semanticLabel: 'Duplicate set ${index + 1}',
            onPressed: onDuplicate,
          ),
          SizedBox(width: AppSpacing.xs),
          GlassIconButton(
            icon: Icons.delete_outline_rounded,
            variant: GlassIconButtonVariant.ghost,
            size: AppIconSize.extraSmall,
            semanticLabel: 'Delete set ${index + 1}',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// The circular complete/uncomplete toggle.
class _CompleteToggle extends StatelessWidget {
  const _CompleteToggle({required this.completed, required this.onTap});

  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final color = completed ? colors.success : colors.onSurfaceMuted;

    return GlassPressable(
      onTap: onTap,
      semanticLabel: completed ? 'Mark set incomplete' : 'Complete set',
      haptic: HapticType.selection,
      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
      child: GlassContainer(
        width: AppSpacing.xxxl,
        height: AppSpacing.xxxl,
        decoration: GlassDecoration(
          color: completed
              ? colors.success.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.extraLarge),
          border: GlassBorder(color: color, width: AppBorderWidth.thin),
        ),
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        child: Center(
          child: completed
              ? Icon(Icons.check_rounded, size: AppIconSize.small, color: color)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// The small set-number label (e.g. "1", or "W1" for a warm-up).
class _SetNumber extends StatelessWidget {
  const _SetNumber({
    required this.index,
    required this.isWarmup,
    required this.color,
  });

  final int index;
  final bool isWarmup;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = isWarmup ? 'W$index' : '${index + 1}';
    return SizedBox(
      width: AppSpacing.xxl,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
