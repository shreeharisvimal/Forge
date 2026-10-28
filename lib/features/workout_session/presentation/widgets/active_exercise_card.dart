// Exercise card shown during the active stage of a workout.
//
// One scrollable page per exercise: header with the remove action, the set
// list ([SetRow] rows), an add-set button and the next-exercise affordance.
// All mutations go through [ActiveSessionController].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/dialogs/forge_dialogs.dart';
import '../../../../core/design/forge_design.dart';
import '../../../../models/workout_set.dart';
import '../../domain/session_formatters.dart';
import '../../domain/session_models.dart';
import '../../providers/session_providers.dart';
import 'set_editor_sheet.dart';
import 'set_row.dart';

/// The per-exercise page of the active stage.
class ActiveExerciseCard extends ConsumerWidget {
  /// Creates an exercise card.
  const ActiveExerciseCard({
    super.key,
    required this.session,
    required this.exerciseIndex,
    required this.unit,
  });

  /// The in-progress session.
  final ActiveSession session;

  /// Index of the exercise this card renders.
  final int exerciseIndex;

  /// The weight unit for display.
  final SessionWeightUnit unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).forgeColors;
    final controller = ref.read(activeSessionProvider.notifier);
    final exercise = session.content.exercises[exerciseIndex];
    final totalSets = exercise.sets.length;
    final isLast = session.isLastExercise;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: GlassDecoration(
            color: colors.glass,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: const GlassBorder(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exercise.exerciseName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  GlassIconButton(
                    icon: Icons.close_rounded,
                    variant: GlassIconButtonVariant.ghost,
                    size: AppIconSize.small,
                    semanticLabel: 'Remove ${exercise.exerciseName}',
                    onPressed: () => _removeExercise(context, controller),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xxs),
              Text(
                '${exercise.sets.length} ${totalSets == 1 ? 'set' : 'sets'} planned',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
              ),
              SizedBox(height: AppSpacing.md),
              for (var i = 0; i < exercise.sets.length; i++)
                SetRow(
                  index: i,
                  set: exercise.sets[i],
                  unit: unit,
                  onCompleteToggle: () => _toggleComplete(
                    controller,
                    exercise.sets[i],
                    i,
                  ),
                  onEdit: () => _editSet(context, controller, i),
                  onDuplicate: () => controller.duplicateSet(exerciseIndex, i),
                  onDelete: () => controller.deleteSet(exerciseIndex, i),
                ),
              SizedBox(height: AppSpacing.sm),
              GlassButton(
                label: 'Add set',
                icon: Icons.add_rounded,
                variant: GlassButtonVariant.tonal,
                expanded: true,
                onPressed: () => controller.addSet(exerciseIndex),
              ),
              if (!isLast) ...[
                SizedBox(height: AppSpacing.md),
                GlassButton(
                  label: 'Next exercise',
                  icon: Icons.arrow_forward_rounded,
                  expanded: true,
                  onPressed: () => controller.nextExercise(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _toggleComplete(
    ActiveSessionController controller,
    WorkoutSet set,
    int setIndex,
  ) {
    controller.updateSet(
      exerciseIndex,
      setIndex,
      set.copyWith(
        completed: !set.completed,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _editSet(
    BuildContext context,
    ActiveSessionController controller,
    int setIndex,
  ) async {
    final updated = await showSetEditor(
      context,
      set: session.content.exercises[exerciseIndex].sets[setIndex],
      unit: unit,
    );
    if (updated == null) return;
    controller.updateSet(exerciseIndex, setIndex, updated);
  }

  Future<void> _removeExercise(
    BuildContext context,
    ActiveSessionController controller,
  ) async {
    final exercise = session.content.exercises[exerciseIndex];
    final confirmed = await showForgeConfirmDialog(
      context,
      title: 'Remove exercise',
      message:
          'Remove ${exercise.exerciseName} and its ${exercise.sets.length} '
          '${exercise.sets.length == 1 ? 'set' : 'sets'} from this workout?',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed == true) {
      controller.removeExercise(exerciseIndex);
    }
  }
}
