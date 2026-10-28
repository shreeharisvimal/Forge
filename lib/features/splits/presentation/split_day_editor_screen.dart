// Day editor screen for the Forge application.
//
// Edits a single [WorkoutSplitDay]: name, focus, rest-day flag and the
// ordered list of exercise assignments. Exercises are picked from the
// library, configured (sets, reps, RPE, rest, tempo) and reordered with
// drag handles. Returns the edited day via [Navigator.pop].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../../../models/exercise.dart';
import '../../../models/workout_split_day.dart';
import '../../../models/workout_split_exercise.dart';
import '../../../services/providers.dart';
import '../split_options.dart';

/// Edits one split day.
class SplitDayEditorScreen extends ConsumerStatefulWidget {
  /// Creates the day editor.
  const SplitDayEditorScreen({super.key, required this.day});

  /// The day being edited.
  final WorkoutSplitDay day;

  @override
  ConsumerState<SplitDayEditorScreen> createState() =>
      _SplitDayEditorScreenState();
}

class _SplitDayEditorScreenState extends ConsumerState<SplitDayEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _focusController;
  late bool _isRestDay;
  late List<WorkoutSplitExercise> _exercises;

  @override
  void initState() {
    super.initState();
    final day = widget.day;
    _nameController = TextEditingController(text: day.name);
    _focusController = TextEditingController(text: day.focus);
    _isRestDay = day.isRestDay;
    _exercises = [...day.exercises];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  void _saveAndPop() {
    final day = WorkoutSplitDay(
      id: widget.day.id,
      name: _nameController.text.trim().isEmpty
          ? 'Untitled Day'
          : _nameController.text.trim(),
      focus: _focusController.text.trim(),
      isRestDay: _isRestDay,
      exercises: _exercises,
    );
    Navigator.of(context).pop(day);
  }

  Future<void> _pickExercise() async {
    final repository = ref.read(exerciseRepositoryProvider);
    final exercises = repository.visible()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final picked = await GlassBottomSheet.show<Exercise>(
      context,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      showDragHandle: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: _ExercisePicker(exercises: exercises),
      ),
    );

    if (picked != null) {
      setState(() {
        _exercises.add(
          WorkoutSplitExercise(
            exerciseId: picked.id,
            exerciseName: picked.name,
            order: _exercises.length,
            sets: picked.defaultSets,
            reps: picked.defaultReps,
            rpe: picked.defaultRpe,
            restSeconds: picked.defaultRestSeconds,
            tempo: picked.tempo,
          ),
        );
      });
    }
  }

  Future<void> _editAssignment(int index) async {
    final edited = await GlassBottomSheet.show<WorkoutSplitExercise>(
      context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _AssignmentEditor(assignment: _exercises[index]),
      ),
    );
    if (edited != null) {
      setState(() => _exercises[index] = edited);
    }
  }

  void _removeAssignment(int index) {
    setState(() {
      _exercises.removeAt(index);
      _renumber();
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final exercise = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, exercise);
      _renumber();
    });
  }

  void _renumber() {
    for (var i = 0; i < _exercises.length; i++) {
      _exercises[i] = _exercises[i].copyWith(order: i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Scaffold(
      body: Column(
        children: [
          GlassAppBar(
            title: _nameController.text.trim().isEmpty
                ? 'Edit Day'
                : _nameController.text.trim(),
            actions: [
              GlassButton(
                label: 'Done',
                size: GlassButtonSize.small,
                onPressed: _saveAndPop,
              ),
            ],
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  GlassTextField(
                    controller: _nameController,
                    label: 'Day name',
                    hintText: 'e.g. Day 1 — Push',
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GlassTextField(
                    controller: _focusController,
                    label: 'Focus (optional)',
                    hintText: 'e.g. Chest / Triceps',
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ToggleRow(
                    title: 'Rest day',
                    subtitle: 'No exercises — recovery or mobility',
                    value: _isRestDay,
                    onChanged: (value) => setState(() => _isRestDay = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GlassDivider(),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Exercises',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      GlassButton(
                        label: 'Add Exercise',
                        icon: Icons.add,
                        variant: GlassButtonVariant.ghost,
                        size: GlassButtonSize.small,
                        onPressed: _isRestDay ? null : _pickExercise,
                      ),
                    ],
                  ),
                  if (_exercises.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Text(
                        _isRestDay
                            ? 'This is a rest day — no exercises.'
                            : 'No exercises yet. Add your first one.',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceMuted,
                                ),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _exercises.length,
                      onReorder: _reorder,
                      buildDefaultDragHandles: false,
                      itemBuilder: (context, index) {
                        final assignment = _exercises[index];
                        return _AssignmentTile(
                          key: ValueKey(assignment.id),
                          assignment: assignment,
                          onTap: () => _editAssignment(index),
                          onRemove: () => _removeAssignment(index),
                          onReorderStart: (details) {
                            // No-op; the drag handle drives reordering.
                          },
                        );
                      },
                    ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet list of library exercises to add to a day.
class _ExercisePicker extends StatelessWidget {
  const _ExercisePicker({required this.exercises});

  final List<Exercise> exercises;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Add exercise',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: exercises.isEmpty
              ? Center(
                  child: Text(
                    'No exercises in your library yet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                  ),
                )
              : ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: GlassListTile(
                        title: exercise.name,
                        subtitle:
                            '${exercise.muscleGroup} · ${exercise.equipment}',
                        leading: Icon(
                          Icons.fitness_center,
                          color: colors.primary,
                        ),
                        onTap: () => Navigator.of(context).pop(exercise),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// One exercise assignment row with a drag handle.
class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({
    super.key,
    required this.assignment,
    required this.onTap,
    required this.onRemove,
    required this.onReorderStart,
  });

  final WorkoutSplitExercise assignment;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final void Function(DragStartDetails) onReorderStart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final rpe = assignment.rpe?.toStringAsFixed(1);
    final rest = formatRestSeconds(assignment.restSeconds);
    final summary = '${assignment.sets}×${assignment.reps}'
        '${rpe == null ? '' : ' · RPE $rpe'}'
        ' · rest $rest'
        '${assignment.tempo.trim().isEmpty ? '' : ' · ${assignment.tempo}'}';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: ReorderableDragStartListener(
              index: assignment.order,
              child: Icon(
                Icons.drag_handle,
                color: colors.onSurfaceTertiary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.exerciseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  summary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceMuted,
                      ),
                ),
              ],
            ),
          ),
          GlassIconButton(
            icon: Icons.remove_circle_outline,
            variant: GlassIconButtonVariant.ghost,
            color: colors.danger,
            semanticLabel: 'Remove exercise',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to configure one assignment's target values.
class _AssignmentEditor extends StatefulWidget {
  const _AssignmentEditor({required this.assignment});

  final WorkoutSplitExercise assignment;

  @override
  State<_AssignmentEditor> createState() => _AssignmentEditorState();
}

class _AssignmentEditorState extends State<_AssignmentEditor> {
  late int _sets;
  late int _reps;
  double? _rpe;
  late int _restSeconds;
  late final TextEditingController _tempoController;

  @override
  void initState() {
    super.initState();
    final assignment = widget.assignment;
    _sets = assignment.sets;
    _reps = assignment.reps;
    _rpe = assignment.rpe;
    _restSeconds = assignment.restSeconds;
    _tempoController = TextEditingController(text: assignment.tempo);
  }

  @override
  void dispose() {
    _tempoController.dispose();
    super.dispose();
  }

  void _done() {
    Navigator.of(context).pop(
      widget.assignment.copyWith(
        sets: _sets,
        reps: _reps,
        rpe: () => _rpe,
        restSeconds: _restSeconds,
        tempo: _tempoController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.assignment.exerciseName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ValueStepper(
            label: 'Sets',
            value: _sets,
            suffix: 'sets',
            min: 1,
            max: 20,
            onChanged: (value) => setState(() => _sets = value),
          ),
          _ValueStepper(
            label: 'Reps',
            value: _reps,
            suffix: 'reps',
            min: 1,
            max: 100,
            onChanged: (value) => setState(() => _reps = value),
          ),
          _ValueStepper(
            label: 'Target RPE',
            value: _rpe?.round() ?? 0,
            suffix: _rpe?.toStringAsFixed(1) ?? 'unset',
            min: 0,
            max: 10,
            onChanged: (value) =>
                setState(() => _rpe = value == 0 ? null : value.toDouble()),
          ),
          _ValueStepper(
            label: 'Rest between sets',
            value: _restSeconds,
            suffix: formatRestSeconds(_restSeconds),
            min: 0,
            max: 600,
            step: 15,
            onChanged: (value) => setState(() => _restSeconds = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassTextField(
            controller: _tempoController,
            label: 'Tempo',
            hintText: 'e.g. 2-1-1',
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassButton(
            label: 'Save',
            expanded: true,
            onPressed: _done,
          ),
        ],
      ),
    );
  }
}

/// A compact +/- stepper used in the assignment editor.
class _ValueStepper extends StatelessWidget {
  const _ValueStepper({
    required this.label,
    required this.value,
    required this.suffix,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final int value;
  final String suffix;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                  ),
            ),
          ),
          GlassIconButton(
            icon: Icons.remove_circle_outline,
            variant: GlassIconButtonVariant.ghost,
            onPressed: value - step >= min
                ? () => onChanged(value - step)
                : null,
          ),
          SizedBox(
            width: 56,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                  ),
            ),
          ),
          GlassIconButton(
            icon: Icons.add_circle_outline,
            variant: GlassIconButtonVariant.ghost,
            onPressed: value + step <= max
                ? () => onChanged(value + step)
                : null,
          ),
          SizedBox(
            width: 56,
            child: Text(
              suffix,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A labeled row with a [GlassSwitch].
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        GlassSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}
