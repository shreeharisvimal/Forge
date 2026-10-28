// Set editor sheet for the active workout.
//
// A bottom sheet for editing a single set's weight, reps, RPE, rest and
// notes. Pops the updated [WorkoutSet] (or null when cancelled).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/forge_design.dart';
import '../../../../models/workout_set.dart';
import '../../domain/session_formatters.dart';

/// Presents the set editor and resolves with the updated [WorkoutSet].
Future<WorkoutSet?> showSetEditor(
  BuildContext context, {
  required WorkoutSet set,
  required SessionWeightUnit unit,
}) {
  return context.showGlassBottomSheet<WorkoutSet>(
    initialChildSize: 0.85,
    maxChildSize: 0.95,
    builder: (_) => SetEditorSheet(set: set, unit: unit),
  );
}

/// The set editor form.
class SetEditorSheet extends StatefulWidget {
  /// Creates the set editor.
  const SetEditorSheet({super.key, required this.set, required this.unit});

  /// The set being edited.
  final WorkoutSet set;

  /// The weight unit for display.
  final SessionWeightUnit unit;

  @override
  State<SetEditorSheet> createState() => _SetEditorSheetState();
}

class _SetEditorSheetState extends State<SetEditorSheet> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late final TextEditingController _notesController;
  double? _rpe;
  int? _rest;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: SessionFormatters.weight(widget.set.weight, widget.unit),
    );
    _repsController = TextEditingController(
      text: widget.set.reps > 0 ? '${widget.set.reps}' : '',
    );
    _notesController = TextEditingController(text: widget.set.notes);
    _rpe = widget.set.rpe;
    _rest = widget.set.restSeconds;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final reps = int.tryParse(_repsController.text) ?? widget.set.reps;
    Navigator.of(context).pop(
      widget.set.copyWith(
        weight: weight < 0 ? 0 : weight,
        reps: reps < 1 ? 1 : reps,
        rpe: () => _rpe,
        restSeconds: _rest ?? widget.set.restSeconds,
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit set',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: GlassTextField(
                  controller: _weightController,
                  label: 'Weight (${widget.unit == SessionWeightUnit.kg ? 'kg' : 'lb'})',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: GlassTextField(
                  controller: _repsController,
                  label: 'Reps',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          GlassDropdown<double>(
            label: 'RPE',
            value: _rpe ?? 0,
            hint: 'None',
            options: [
              const GlassDropdownOption(label: 'None', value: 0),
              for (var rpe = 6.0; rpe <= 10.0; rpe += 0.5)
                GlassDropdownOption(
                  label: rpe == rpe.roundToDouble()
                      ? 'RPE ${rpe.toInt()}'
                      : 'RPE $rpe',
                  value: rpe,
                ),
            ],
            onChanged: (value) => setState(() => _rpe = value == 0 ? null : value),
          ),
          SizedBox(height: AppSpacing.md),
          GlassDropdown<int>(
            label: 'Rest after set',
            value: _rest ?? 0,
            hint: 'None',
            options: const [
              GlassDropdownOption(label: 'No rest', value: 0),
              GlassDropdownOption(label: '30s', value: 30),
              GlassDropdownOption(label: '45s', value: 45),
              GlassDropdownOption(label: '60s', value: 60),
              GlassDropdownOption(label: '90s', value: 90),
              GlassDropdownOption(label: '2 min', value: 120),
              GlassDropdownOption(label: '3 min', value: 180),
              GlassDropdownOption(label: '4 min', value: 240),
            ],
            onChanged: (value) => setState(() => _rest = value),
          ),
          SizedBox(height: AppSpacing.md),
          GlassTextField(
            controller: _notesController,
            label: 'Notes',
            hintText: 'Optional...',
            maxLines: 2,
          ),
          SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Cancel',
                  variant: GlassButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: GlassButton(
                  label: 'Save',
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
