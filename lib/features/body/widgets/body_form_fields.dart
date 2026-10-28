// Body measurement form fields for the Forge application.
//
// The numeric input grid (weight, body fat and every girth/length field)
// plus the notes editor. Pure presentation; the owning sheet drives state.
library;

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';
import '../domain/body_measurement_fields.dart';

/// The numeric inputs of the body measurement form.
class BodyFormFields extends StatelessWidget {
  /// Creates the measurement fields.
  const BodyFormFields({
    super.key,
    required this.controllers,
    required this.notesController,
    required this.weightUnit,
    required this.lengthUnit,
    this.onChanged,
  });

  /// Controllers keyed by measurement field.
  final Map<BodyField, TextEditingController> controllers;

  /// The notes editor controller.
  final TextEditingController notesController;

  /// Weight unit label ('kg' or 'lb').
  final String weightUnit;

  /// Length unit label ('cm' or 'in').
  final String lengthUnit;

  /// Invoked when any input changes.
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldRow(
          field: BodyField.weight,
          controller: controllers[BodyField.weight]!,
          unit: weightUnit,
          onChanged: onChanged,
        ),
        SizedBox(height: AppSpacing.md),
        _fieldRow(
          field: BodyField.bodyFat,
          controller: controllers[BodyField.bodyFat]!,
          unit: '%',
          onChanged: onChanged,
        ),
        SizedBox(height: AppSpacing.md),
        _pair(
          fieldA: BodyField.waist,
          fieldB: BodyField.hip,
          controllers: controllers,
          unit: lengthUnit,
          onChanged: onChanged,
        ),
        SizedBox(height: AppSpacing.md),
        _pair(
          fieldA: BodyField.chest,
          fieldB: BodyField.neck,
          controllers: controllers,
          unit: lengthUnit,
          onChanged: onChanged,
        ),
        SizedBox(height: AppSpacing.md),
        _fieldRow(
          field: BodyField.shoulders,
          controller: controllers[BodyField.shoulders]!,
          unit: lengthUnit,
          onChanged: onChanged,
        ),
        SizedBox(height: AppSpacing.md),
        _pair(
          fieldA: BodyField.leftArm,
          fieldB: BodyField.rightArm,
          controllers: controllers,
          unit: lengthUnit,
          onChanged: onChanged,
        ),
        SizedBox(height: AppSpacing.md),
        _pair(
          fieldA: BodyField.leftForearm,
          fieldB: BodyField.rightForearm,
          controllers: controllers,
          unit: lengthUnit,
          onChanged: onChanged,
        ),
        SizedBox(height: AppSpacing.md),
        _pair(
          fieldA: BodyField.leftThigh,
          fieldB: BodyField.rightThigh,
          controllers: controllers,
          unit: lengthUnit,
          onChanged: onChanged,
        ),
        SizedBox(height: AppSpacing.md),
        _pair(
          fieldA: BodyField.leftCalf,
          fieldB: BodyField.rightCalf,
          controllers: controllers,
          unit: lengthUnit,
          onChanged: onChanged,
        ),
        SizedBox(height: AppSpacing.lg),
        GlassTextField(
          controller: notesController,
          label: 'Notes',
          hintText: 'How did you feel, bloat, pump...',
          maxLines: 3,
          textInputAction: TextInputAction.newline,
          onChanged: (_) => onChanged?.call(),
        ),
      ],
    );
  }

  Widget _pair({
    required BodyField fieldA,
    required BodyField fieldB,
    required Map<BodyField, TextEditingController> controllers,
    required String unit,
    required VoidCallback? onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: _fieldRow(
            field: fieldA,
            controller: controllers[fieldA]!,
            unit: unit,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _fieldRow(
            field: fieldB,
            controller: controllers[fieldB]!,
            unit: unit,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _fieldRow({
    required BodyField field,
    required TextEditingController controller,
    required String unit,
    required VoidCallback? onChanged,
  }) {
    final icon = _icon(field.iconName);
    return GlassTextField(
      controller: controller,
      label: '${field.label} ($unit)',
      hintText: '—',
      prefixIcon: icon,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onChanged: (_) => onChanged?.call(),
    );
  }

  IconData? _icon(String name) => switch (name) {
        'weight' => Icons.monitor_weight_outlined,
        'bodyFat' => Icons.percent_rounded,
        'waist' => Icons.straighten_rounded,
        'hip' => Icons.straighten_rounded,
        'chest' => Icons.accessibility_new_rounded,
        'neck' => Icons.straighten_rounded,
        'shoulders' => Icons.accessibility_new_rounded,
        _ => Icons.straighten_rounded,
      };
}
