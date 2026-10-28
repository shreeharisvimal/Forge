// Active stage of the workout session.
//
// The performing stage: live stats strip, rest timer banner, an exercise
// pager that stays in sync with [SessionUiState.currentExerciseIndex], and
// the finish/abandon actions. The pager only rebuilds on session mutations;
// the ticking clocks live inside their own widgets.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dialogs/forge_dialogs.dart';
import '../../../../core/design/forge_design.dart';
import '../../../../models/workout_exercise.dart';
import '../../../../models/workout_set.dart';
import '../../../../services/providers.dart';
import '../../domain/session_formatters.dart';
import '../../domain/session_models.dart';
import '../../providers/session_providers.dart';
import 'active_exercise_card.dart';
import 'exercise_picker_sheet.dart';
import 'rest_timer_banner.dart';
import 'session_stats_bar.dart';

/// The active stage content.
class ActiveStage extends ConsumerStatefulWidget {
  /// Creates the active stage.
  const ActiveStage({super.key, required this.session});

  /// The in-progress (active) session.
  final ActiveSession session;

  @override
  ConsumerState<ActiveStage> createState() => _ActiveStageState();
}

class _ActiveStageState extends ConsumerState<ActiveStage> {
  final PageController _pageController = PageController();
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.session.ui.currentExerciseIndex;
  }

  @override
  void didUpdateWidget(covariant ActiveStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = widget.session.ui.currentExerciseIndex;
    if (index == oldWidget.session.ui.currentExerciseIndex) return;
    if (index == _lastIndex) return;
    _lastIndex = index;
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: AppDuration.quick,
      curve: AppCurves.standard,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  ActiveSessionController get _controller =>
      ref.read(activeSessionProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final exerciseCount = session.content.exercises.length;
    final current = session.ui.currentExerciseIndex.clamp(0, exerciseCount - 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const SessionStatsBar(),
          const RestTimerBanner(),
          if (exerciseCount > 0) ...[
            _ExerciseSwitcher(
              current: current,
              total: exerciseCount,
              onPrevious: current > 0 ? () => _controller.focusExercise(current - 1) : null,
              onNext:
                  current < exerciseCount - 1
                      ? () => _controller.focusExercise(current + 1)
                      : null,
            ),
            SizedBox(height: AppSpacing.md),
          ],
          Expanded(
            child: exerciseCount == 0
                ? _EmptyActive(onAdd: _addExercise, onFinish: _finish)
                : PageView.builder(
                    controller: _pageController,
                    itemCount: exerciseCount,
                    onPageChanged: (index) {
                      _lastIndex = index;
                      if (index != session.ui.currentExerciseIndex) {
                        _controller.focusExercise(index);
                      }
                    },
                    itemBuilder: (context, index) => ActiveExerciseCard(
                      session: session,
                      exerciseIndex: index,
                      unit: SessionWeightUnit.fromSettings(
                        ref.watch(settingsProvider).weightUnit,
                      ),
                    ),
                  ),
          ),
          SizedBox(height: AppSpacing.md),
          _ActionBar(onAbandon: _abandon, onFinish: _finish),
        ],
      ),
    );
  }

  Future<void> _addExercise() async {
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

  Future<void> _finish() async {
    await _controller.finish();
  }

  Future<void> _abandon() async {
    final confirmed = await showForgeConfirmDialog(
      context,
      title: 'Abandon workout',
      message: 'This workout and all its sets will be discarded.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    await _controller.abandon();
    if (mounted) context.pop();
  }
}

/// Exercise navigation row with a completion progress bar.
class _ExerciseSwitcher extends StatelessWidget {
  const _ExerciseSwitcher({
    required this.current,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final int current;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Row(
      children: [
        GlassIconButton(
          icon: Icons.chevron_left_rounded,
          variant: GlassIconButtonVariant.glass,
          size: AppIconSize.medium,
          semanticLabel: 'Previous exercise',
          onPressed: onPrevious,
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            children: [
              Text(
                'Exercise ${current + 1} of $total',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: AppSpacing.xs),
              GlassProgressBar(
                value: (current + 1) / total,
                height: 5,
              ),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        GlassIconButton(
          icon: Icons.chevron_right_rounded,
          variant: GlassIconButtonVariant.glass,
          size: AppIconSize.medium,
          semanticLabel: 'Next exercise',
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// The finish/abandon action bar.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onAbandon, required this.onFinish});

  final VoidCallback onAbandon;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassButton(
            label: 'Abandon',
            icon: Icons.close_rounded,
            variant: GlassButtonVariant.ghost,
            onPressed: onAbandon,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: GlassButton(
            label: 'Finish workout',
            icon: Icons.flag_rounded,
            variant: GlassButtonVariant.filled,
            onPressed: onFinish,
          ),
        ),
      ],
    );
  }
}

/// Empty active state (no exercises).
class _EmptyActive extends StatelessWidget {
  const _EmptyActive({required this.onAdd, required this.onFinish});

  final VoidCallback onAdd;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return GlassEmptyState(
      icon: Icons.fitness_center_rounded,
      title: 'No exercises',
      message: 'Add an exercise to begin this workout.',
      action: Column(
        children: [
          GlassButton(
            label: 'Add exercise',
            icon: Icons.add_rounded,
            variant: GlassButtonVariant.tonal,
            onPressed: onAdd,
          ),
          SizedBox(height: AppSpacing.sm),
          GlassButton(
            label: 'Finish workout',
            icon: Icons.flag_rounded,
            variant: GlassButtonVariant.ghost,
            onPressed: onFinish,
          ),
        ],
      ),
    );
  }
}
