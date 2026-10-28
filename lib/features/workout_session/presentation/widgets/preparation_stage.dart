// Preparation stage of the workout session.
//
// Lets the user confirm the planned workout before starting: edit the
// session name, review the exercises and targets, toggle warm-up sets,
// add/remove exercises, then start. Everything is read from the in-progress
// session and mutated through [ActiveSessionController].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/forge_design.dart';
import '../../../../models/workout_set.dart';
import '../../../../models/workout_exercise.dart';
import '../../../../services/providers.dart';
import '../../domain/session_formatters.dart';
import '../../domain/session_models.dart';
import '../../providers/session_providers.dart';
import 'exercise_picker_sheet.dart';

/// The preparation stage content.
class PreparationStage extends ConsumerStatefulWidget {
  /// Creates the preparation stage.
  const PreparationStage({super.key, required this.session});

  /// The in-progress (preparation) session.
  final ActiveSession session;

  @override
  ConsumerState<PreparationStage> createState() => _PreparationStageState();
}

class _PreparationStageState extends ConsumerState<PreparationStage> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.session.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  ActiveSessionController get _controller =>
      ref.read(activeSessionProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final prep = ref.watch(sessionPreparationProvider);
    final unit = SessionWeightUnit.fromSettings(
      ref.watch(settingsProvider).weightUnit,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassTextField(
                  controller: _nameController,
                  label: 'Workout name',
                  hintText: 'e.g. Push day',
                  prefixIcon: Icons.edit_rounded,
                  onChanged: _controller.updateSessionName,
                ),
                SizedBox(height: AppSpacing.lg),
                _PrepStats(
                  minutes: prep.estimatedMinutes,
                  sets: prep.targetSets,
                  volume: SessionFormatters.volume(prep.targetVolume, unit),
                  muscles: prep.muscleGroups,
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Exercises',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.forgeColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: AppSpacing.md),
                if (widget.session.content.exercises.isEmpty)
                  _EmptyPrep(onAdd: () => _addExercise(context))
                else
                  for (var i = 0;
                      i < widget.session.content.exercises.length;
                      i++)
                    _PreparedExerciseCard(
                      session: widget.session,
                      index: i,
                      unit: unit,
                      onToggleWarmup: () => _controller
                          .toggleWarmup(widget.session.content.exercises[i].id),
                      onRemove: () => _controller.removeExercise(i),
                    ),
                SizedBox(height: AppSpacing.md),
                GlassButton(
                  label: 'Add exercise',
                  icon: Icons.add_rounded,
                  variant: GlassButtonVariant.tonal,
                  expanded: true,
                  onPressed: () => _addExercise(context),
                ),
                SizedBox(height: AppSpacing.xxl),
                GlassButton(
                  label: 'Start workout',
                  icon: Icons.play_arrow_rounded,
                  size: GlassButtonSize.large,
                  expanded: true,
                  onPressed: _controller.start,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addExercise(BuildContext context) async {
    final excluded = {
      for (final exercise in widget.session.content.exercises)
        exercise.exerciseId,
    };
    final exercise = await showExercisePicker(context, excludedIds: excluded);
    if (exercise == null || !mounted) return;
    _controller.addExercise(
      WorkoutExercise(
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        sets: [
          WorkoutSet(
            weight: 0,
            reps: exercise.defaultReps,
            restSeconds: exercise.defaultRestSeconds,
            completed: false,
          ),
        ],
      ),
    );
  }
}

/// The estimated-stats strip of the preparation screen.
class _PrepStats extends StatelessWidget {
  const _PrepStats({
    required this.minutes,
    required this.sets,
    required this.volume,
    required this.muscles,
  });

  final int minutes;
  final int sets;
  final String volume;
  final List<String> muscles;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return GlassContainer(
      decoration: GlassDecoration(
        color: colors.glass,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: const GlassBorder(),
      ),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _StatChip(icon: Icons.schedule_rounded, label: '~$minutes min')),
              Expanded(child: _StatChip(icon: Icons.repeat_rounded, label: '$sets sets')),
              Expanded(child: _StatChip(icon: Icons.scale_rounded, label: volume)),
            ],
          ),
          if (muscles.isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final muscle in muscles)
                  GlassChip(label: muscle, onTap: null),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Row(
      children: [
        Icon(icon, size: AppIconSize.extraSmall, color: colors.primary),
        SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

/// One prepared exercise with its warm-up toggle and remove action.
class _PreparedExerciseCard extends StatelessWidget {
  const _PreparedExerciseCard({
    required this.session,
    required this.index,
    required this.unit,
    required this.onToggleWarmup,
    required this.onRemove,
  });

  final ActiveSession session;
  final int index;
  final SessionWeightUnit unit;
  final VoidCallback onToggleWarmup;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final exercise = session.content.exercises[index];
    final sets = exercise.sets.where((set) => !set.isWarmup).toList();
    final working = sets.isEmpty ? exercise.sets : sets;
    final targetReps =
        working.isEmpty || working.first.reps <= 0 ? '—' : '${working.first.reps}';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              GlassIconButton(
                icon: Icons.close_rounded,
                variant: GlassIconButtonVariant.ghost,
                size: AppIconSize.small,
                semanticLabel: 'Remove ${exercise.exerciseName}',
                onPressed: onRemove,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            '${working.length} × $targetReps reps',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
          ),
          if (session.warmupEnabled(exercise.id)) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              '2 warm-up sets will be added before the working sets.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.primary,
                  ),
            ),
          ],
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                'Warm-up',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
              ),
              SizedBox(width: AppSpacing.sm),
              GlassSwitch(
                value: session.warmupEnabled(exercise.id),
                onChanged: (_) => onToggleWarmup(),
                semanticLabel: 'Add warm-up sets for ${exercise.exerciseName}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Empty preparation state with an add button.
class _EmptyPrep extends StatelessWidget {
  const _EmptyPrep({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GlassEmptyState(
      icon: Icons.fitness_center_rounded,
      title: 'No exercises yet',
      message: 'Add exercises from your library to build the workout.',
      action: GlassButton(
        label: 'Add exercise',
        icon: Icons.add_rounded,
        variant: GlassButtonVariant.tonal,
        onPressed: onAdd,
      ),
    );
  }
}
