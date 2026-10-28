// Progress exercise-analytics section for the Forge application.
//
// The window's most-performed exercises ranked by volume, each showing its
// session/set counts, tonnage and estimated-1RM movement since the start of
// the window.
library;

import 'package:flutter/material.dart';

import '../../../../core/design/forge_design.dart';
import '../../workout_session/domain/session_formatters.dart';
import '../domain/analytics_models.dart';
import 'progress_section_header.dart';

/// The exercise-analytics list for one [AnalyticsSnapshot].
class ProgressExerciseSection extends StatelessWidget {
  /// Creates the exercise section.
  const ProgressExerciseSection({
    super.key,
    required this.snapshot,
    required this.unit,
    this.limit = 6,
  });

  /// The snapshot to render.
  final AnalyticsSnapshot snapshot;

  /// The weight unit for display.
  final SessionWeightUnit unit;

  /// The number of top exercises to show.
  final int limit;

  @override
  Widget build(BuildContext context) {
    final exercises = snapshot.exercises.take(limit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProgressSectionHeader(
          title: 'Top exercises',
          subtitle: 'By volume',
        ),
        SizedBox(height: AppSpacing.md),
        if (exercises.isEmpty)
          _EmptyExercises()
        else
          for (final exercise in exercises)
            GlassExerciseTile(
              title: exercise.exerciseName,
              subtitle:
                  '${exercise.muscleGroup.isEmpty ? 'Uncategorized' : exercise.muscleGroup}'
                  ' · ${exercise.sessions} '
                  '${exercise.sessions == 1 ? 'session' : 'sessions'}',
              tags: [
                SessionFormatters.volume(exercise.volume, unit),
                '${exercise.sets} sets',
              ],
              trailing: _OneRmDelta(delta: exercise.estOneRMDelta, unit: unit),
            ),
      ],
    );
  }
}

/// The estimated-1RM movement chip for one exercise.
class _OneRmDelta extends StatelessWidget {
  const _OneRmDelta({required this.delta, required this.unit});

  final double delta;
  final SessionWeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    if (delta == 0) {
      return Text(
        SessionFormatters.weight(delta, unit),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceMuted,
            ),
      );
    }

    final improving = delta > 0;
    final color = improving ? colors.success : colors.danger;
    return Semantics(
      label: '${improving ? 'Up' : 'Down'} '
          '${delta.abs().toStringAsFixed(1)} estimated 1RM',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            improving ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: AppIconSize.small,
            color: color,
          ),
          SizedBox(width: AppSpacing.xxs),
          Text(
            '${improving ? '+' : ''}${SessionFormatters.weight(delta, unit)}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// A compact empty card when no exercises were tracked in the window.
class _EmptyExercises extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return GlassContainer(
      width: double.infinity,
      padding: AppSpacing.xl.all,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      decoration: GlassDecoration(
        color: colors.glass,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: const GlassBorder(),
      ),
      child: Text(
        'No exercises tracked in this window yet.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceMuted,
            ),
      ),
    );
  }
}
