// Measurement fields for the Forge application.
//
// The editable body-measurement form inside the day-detail sheet: every girth
// plus body-fat percentage as glass inputs, paired left/right for symmetry.
// Pure presentation; the owning page persists through the calendar editor.
library;

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';
import '../domain/calendar_models.dart';

/// The full body-measurement form of the day-detail sheet.
class MeasurementFieldsSection extends StatelessWidget {
  /// Creates the measurement form.
  const MeasurementFieldsSection({
    super.key,
    required this.unit,
    required this.controllers,
    required this.onChanged,
  });

  /// Length unit label, e.g. "cm".
  final String unit;

  /// One controller per editable field.
  final Map<MeasurementField, TextEditingController> controllers;

  /// Invoked when any field changes.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return GlassContainer(
      decoration: GlassDecoration(
        color: colors.glass,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: const GlassBorder(),
      ),
      borderRadius: BorderRadius.circular(AppRadius.large),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.straighten_rounded,
                size: AppIconSize.small,
                color: colors.info,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Measurements',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: colors.onSurface),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          _row(context, [MeasurementField.waist, MeasurementField.chest]),
          SizedBox(height: AppSpacing.md),
          _row(context, [MeasurementField.neck, MeasurementField.shoulders]),
          SizedBox(height: AppSpacing.md),
          _row(context, [MeasurementField.leftArm, MeasurementField.rightArm]),
          SizedBox(height: AppSpacing.md),
          _row(
            context,
            [MeasurementField.leftForearm, MeasurementField.rightForearm],
          ),
          SizedBox(height: AppSpacing.md),
          _row(context, [MeasurementField.leftThigh, MeasurementField.rightThigh]),
          SizedBox(height: AppSpacing.md),
          _row(context, [MeasurementField.leftCalf, MeasurementField.rightCalf]),
          SizedBox(height: AppSpacing.md),
          _field(context, MeasurementField.bodyFat),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, List<MeasurementField> fields) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _field(context, fields[0])),
        SizedBox(width: AppSpacing.md),
        Expanded(child: _field(context, fields[1])),
      ],
    );
  }

  Widget _field(BuildContext context, MeasurementField field) {
    final (label, icon) = _spec(field);
    return GlassTextField(
      controller: controllers[field],
      label: label,
      hintText: 'Optional',
      prefixIcon: icon,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onChanged(),
    );
  }

  (String, IconData) _spec(MeasurementField field) {
    switch (field) {
      case MeasurementField.waist:
        return ('Waist ($unit)', Icons.linear_scale_outlined);
      case MeasurementField.chest:
        return ('Chest ($unit)', Icons.linear_scale_outlined);
      case MeasurementField.neck:
        return ('Neck ($unit)', Icons.linear_scale_outlined);
      case MeasurementField.shoulders:
        return ('Shoulders ($unit)', Icons.linear_scale_outlined);
      case MeasurementField.leftArm:
        return ('Left arm ($unit)', Icons.linear_scale_outlined);
      case MeasurementField.rightArm:
        return ('Right arm ($unit)', Icons.linear_scale_outlined);
      case MeasurementField.leftForearm:
        return ('Left forearm ($unit)', Icons.linear_scale_outlined);
      case MeasurementField.rightForearm:
        return ('Right forearm ($unit)', Icons.linear_scale_outlined);
      case MeasurementField.leftThigh:
        return ('Left thigh ($unit)', Icons.linear_scale_outlined);
      case MeasurementField.rightThigh:
        return ('Right thigh ($unit)', Icons.linear_scale_outlined);
      case MeasurementField.leftCalf:
        return ('Left calf ($unit)', Icons.linear_scale_outlined);
      case MeasurementField.rightCalf:
        return ('Right calf ($unit)', Icons.linear_scale_outlined);
      case MeasurementField.bodyFat:
        return ('Body fat (%)', Icons.percent_rounded);
    }
  }
}
