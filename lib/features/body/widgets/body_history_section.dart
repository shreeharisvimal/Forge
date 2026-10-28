// Body history section for the Forge application.
//
// A compact list of the most recent measurement days. Tapping a row opens
// the measurement form prefilled for that day so users can backfill or edit.
// Pure presentation; the owning screen wires the tap callback.
library;

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';
import '../../../models/body_measurement.dart';
import '../../../models/settings_model.dart';
import '../domain/body_measurement_fields.dart';
import '../presentation/body_formatters.dart';

/// The recent-measurements list.
class BodyHistorySection extends StatelessWidget {
  /// Creates the history section.
  const BodyHistorySection({
    super.key,
    required this.measurements,
    required this.settings,
    required this.onEdit,
  });

  /// The measurements to list, newest first.
  final List<BodyMeasurement> measurements;

  /// The current settings (units).
  final SettingsModel settings;

  /// Invoked with a measurement to edit.
  final ValueChanged<BodyMeasurement> onEdit;

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).forgeColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: AppIconSize.small,
              color: colors.secondary,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              'History',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: colors.onSurface),
            ),
            Spacer(),
            Text(
              '${measurements.length} ${measurements.length == 1 ? 'entry' : 'entries'}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.onSurfaceMuted),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        GlassContainer(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          decoration: GlassDecoration(
            color: colors.glass,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: const GlassBorder(),
          ),
          child: Column(
            children: [
              for (var i = 0; i < measurements.length; i++) ...[
                _HistoryTile(
                  measurement: measurements[i],
                  settings: settings,
                  onTap: () => onEdit(measurements[i]),
                ),
                if (i != measurements.length - 1)
                  GlassDivider(
                    thickness: AppBorderWidth.hairline,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A single history row with the day's headline fields.
class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.measurement,
    required this.settings,
    required this.onTap,
  });

  final BodyMeasurement measurement;
  final SettingsModel settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final date = measurement.date;

    final pieces = [
      for (final field in BodyField.headlineFields)
        if (field.valueOf(measurement) != null)
          '${field.label} ${BodyFormatters.valueWithUnit(
            field.valueOf(measurement)!,
            field,
            settings,
          )}',
    ];

    return GlassPressable(
      onTap: onTap,
      haptic: HapticType.selection,
      borderRadius: BorderRadius.zero,
      semanticLabel: 'Edit measurements for ${_dayLabel(date)}',
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dayLabel(date),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: colors.onSurface),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    pieces.isEmpty ? 'Notes only' : pieces.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.onSurfaceMuted),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurfaceMuted,
              size: AppIconSize.medium,
            ),
          ],
        ),
      ),
    );
  }

  static String _dayLabel(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, '
        '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
