// Create / edit screen for an exercise in the library.
//
// A full form covering identity (name, muscle group, equipment), classification
// (compound, secondary muscles, tags), default workout settings (rest, sets,
// reps, RPE, tempo) and coaching content (instructions, notes). Names are
// validated as non-empty and unique within the library.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/exercise_categories.dart';
import '../../../core/design/forge_design.dart';
import '../../../core/dialogs/forge_dialogs.dart';
import '../../../core/overlays/forge_overlay_extensions.dart';
import '../../../models/exercise.dart';
import '../../../services/providers.dart';
import 'widgets/tag_input_field.dart';

/// Creates or edits an [Exercise].
class ExerciseEditScreen extends ConsumerStatefulWidget {
  /// Creates the editor, pre-filled from [exercise] when editing.
  const ExerciseEditScreen({super.key, this.exercise});

  /// The exercise being edited, or null to create a new one.
  final Exercise? exercise;

  @override
  ConsumerState<ExerciseEditScreen> createState() => _ExerciseEditScreenState();
}

class _ExerciseEditScreenState extends ConsumerState<ExerciseEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _notesController;
  late final TextEditingController _tempoController;

  late String? _muscleGroup;
  late String? _equipment;
  late bool _isCompound;
  late int _defaultRestSeconds;
  late int _defaultSets;
  late int _defaultReps;
  double? _defaultRpe;
  late List<String> _tags;
  late List<String> _secondaryMuscles;

  String? _nameError;

  bool get _isEditing => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    final exercise = widget.exercise;
    _nameController = TextEditingController(text: exercise?.name ?? '');
    _instructionsController =
        TextEditingController(text: exercise?.instructions ?? '');
    _notesController = TextEditingController(text: exercise?.notes ?? '');
    _tempoController = TextEditingController(text: exercise?.tempo ?? '');
    _muscleGroup = exercise?.muscleGroup;
    _equipment = exercise?.equipment;
    _isCompound = exercise?.isCompound ?? false;
    _defaultRestSeconds = exercise?.defaultRestSeconds ?? 90;
    _defaultSets = exercise?.defaultSets ?? 3;
    _defaultReps = exercise?.defaultReps ?? 10;
    _defaultRpe = exercise?.defaultRpe;
    _tags = [...?exercise?.tags];
    _secondaryMuscles = [...?exercise?.secondaryMuscles];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    _tempoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Name is required');
      return;
    }
    setState(() => _nameError = null);

    final repository = ref.read(exerciseRepositoryProvider);
    final existing = repository.byName(name);
    if (existing != null && existing.id != widget.exercise?.id) {
      _showDuplicateError();
      return;
    }

    final base = widget.exercise;
    await repository.save(
      Exercise(
        id: base?.id,
        name: name,
        muscleGroup: _muscleGroup ?? '',
        equipment: _equipment ?? '',
        isCompound: _isCompound,
        notes: _notesController.text.trim(),
        instructions: _instructionsController.text.trim(),
        defaultRestSeconds: _defaultRestSeconds,
        defaultSets: _defaultSets,
        defaultReps: _defaultReps,
        defaultRpe: _defaultRpe,
        tempo: _tempoController.text.trim(),
        tags: _tags,
        secondaryMuscles: _secondaryMuscles,
        favorite: base?.favorite ?? false,
        source: base?.source ?? ExerciseSource.user,
        archived: base?.archived ?? false,
        usageCount: base?.usageCount ?? 0,
        lastUsedAt: base?.lastUsedAt,
        createdAt: base?.createdAt,
        updatedAt: base?.updatedAt,
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _showDuplicateError() {
    context.showToast('"${_nameController.text.trim()}" already exists.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GlassAppBar(
            title: _isEditing ? 'Edit Exercise' : 'New Exercise',
            actions: [
              GlassButton(
                label: 'Save',
                size: GlassButtonSize.small,
                onPressed: _save,
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
                    label: 'Name',
                    hintText: 'e.g. Incline Bench Press',
                    textCapitalization: TextCapitalization.words,
                    errorText: _nameError,
                    onChanged: (_) {
                      if (_nameError != null) {
                        setState(() => _nameError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _SelectionField<String>(
                          label: 'Muscle group',
                          value: _muscleGroup,
                          items: MuscleGroups.all,
                          onChanged: (value) =>
                              setState(() => _muscleGroup = value),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: _SelectionField<String>(
                          label: 'Equipment',
                          value: _equipment,
                          items: Equipment.all,
                          onChanged: (value) =>
                              setState(() => _equipment = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ToggleRow(
                    title: 'Compound exercise',
                    subtitle: 'Multi-joint, multi-muscle movement',
                    value: _isCompound,
                    onChanged: (value) => setState(() => _isCompound = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GlassDivider(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Default workout settings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).forgeColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _StepperRow(
                    label: 'Rest between sets',
                    suffix: 'sec',
                    value: _defaultRestSeconds.toDouble(),
                    min: 0,
                    max: 600,
                    step: 15,
                    onChanged: (value) =>
                        setState(() => _defaultRestSeconds = value.toInt()),
                  ),
                  _StepperRow(
                    label: 'Working sets',
                    suffix: 'sets',
                    value: _defaultSets.toDouble(),
                    min: 1,
                    max: 20,
                    step: 1,
                    onChanged: (value) =>
                        setState(() => _defaultSets = value.toInt()),
                  ),
                  _StepperRow(
                    label: 'Reps per set',
                    suffix: 'reps',
                    value: _defaultReps.toDouble(),
                    min: 0,
                    max: 100,
                    step: 1,
                    onChanged: (value) =>
                        setState(() => _defaultReps = value.toInt()),
                  ),
                  _StepperRow(
                    label: 'Target RPE',
                    suffix: 'unset',
                    value: _defaultRpe ?? 0,
                    min: 0,
                    max: 10,
                    step: 0.5,
                    precision: 1,
                    displayValue: _defaultRpe?.toStringAsFixed(1) ?? 'unset',
                    onChanged: (value) =>
                        setState(() => _defaultRpe = value == 0 ? null : value),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GlassTextField(
                    controller: _tempoController,
                    label: 'Tempo',
                    hintText: 'e.g. 2-1-1 or hold',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GlassDivider(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Coaching',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).forgeColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GlassTextField(
                    controller: _instructionsController,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    label: 'Instructions',
                    hintText: 'How to perform the movement…',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GlassTextField(
                    controller: _notesController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    label: 'Notes',
                    hintText: 'Cues, cautions, programming tips…',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TagInputField(
                    label: 'Secondary muscles',
                    hint: 'Add a muscle group…',
                    values: _secondaryMuscles,
                    onChanged: (values) =>
                        setState(() => _secondaryMuscles = values),
                    suggestions: MuscleGroups.all,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TagInputField(
                    label: 'Tags',
                    hint: 'Add a tag…',
                    values: _tags,
                    onChanged: (values) => setState(() => _tags = values),
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

/// A tappable glass field that picks one value from [items] via the Forge
/// selection dialog.
class _SelectionField<T> extends StatelessWidget {
  const _SelectionField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  Future<void> _open(BuildContext context) async {
    final picked = await showForgeSelectionDialog<T>(
      context,
      title: label,
      selected: value,
      options: [
        for (final item in items)
          ForgeSelectionOption(label: item.toString(), value: item),
      ],
    );
    if (picked != null && context.mounted) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final radius = BorderRadius.circular(AppRadius.medium);
    final selection = value?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
          ),
        ),
        GlassPressable(
          onTap: () => _open(context),
          semanticLabel: label,
          borderRadius: radius,
          child: GlassContainer(
            height: 52,
            borderRadius: radius,
            decoration: GlassDecoration(
              color: colors.glass,
              borderRadius: radius,
              border: const GlassBorder(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selection ?? 'Select…',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: selection == null
                              ? colors.onSurfaceMuted
                              : colors.onSurface,
                        ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.onSurfaceTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
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

/// A stepper row for integer or decimal values.
class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.suffix,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.precision = 0,
    this.displayValue,
  });

  final String label;
  final String suffix;
  final double value;
  final double min;
  final double max;
  final double step;
  final int precision;
  final String? displayValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final shown =
        displayValue ?? (precision == 0 ? value.round().toString() : value.toStringAsFixed(precision));
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
              shown,
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
            width: 48,
            child: Text(
              suffix,
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
