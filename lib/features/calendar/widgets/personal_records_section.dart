// Personal-records section for the Forge application.
//
// The "Records achieved" panel in the day-detail sheet. Purely presentational:
// it renders the [CalendarPrEntry]s the owning page computed from the day's
// sessions, surfacing the lifetime bests each logged exercise contributed to.
library;

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';
import '../../dashboard/widgets/dashboard_formatters.dart';
import '../domain/calendar_models.dart';

/// A glass card listing the personal records behind a day's workouts.
class PersonalRecordsSection extends StatelessWidget {
  /// Creates the records section.
  const PersonalRecordsSection({
    super.key,
    required this.entries,
    required this.weightUnit,
  });

  /// The records achieved, sorted by exercise name.
  final List<CalendarPrEntry> entries;

  /// Weight unit label, e.g. "kg".
  final String weightUnit;

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
                Icons.emoji_events_outlined,
                size: AppIconSize.small,
                color: colors.warning,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Records achieved',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: colors.onSurface),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          for (var index = 0; index < entries.length; index++) ...[
            if (index > 0) ...[
              SizedBox(height: AppSpacing.sm),
              const GlassDivider(thickness: AppBorderWidth.thin),
              SizedBox(height: AppSpacing.sm),
            ],
            _RecordRow(entry: entries[index], weightUnit: weightUnit),
          ],
        ],
      ),
    );
  }
}

/// One exercise's bests: name plus the four headline stats.
class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.entry, required this.weightUnit});

  final CalendarPrEntry entry;
  final String weightUnit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final stats = <_Stat>[
      _Stat(
        label: 'Heaviest',
        value: formatWeight(entry.highestWeight, weightUnit),
      ),
      _Stat(label: 'Best reps', value: '${entry.bestReps}'),
      _Stat(
        label: 'Est. 1RM',
        value: formatWeight(entry.estimatedOneRM, weightUnit),
      ),
      _Stat(label: 'Best volume', value: _formatVolume(entry.bestVolume)),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.exerciseName,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.onSurface),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Records you hold',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: colors.onSurfaceMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        for (final stat in stats) ...[
          SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stat.value,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                stat.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static String _formatVolume(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

/// A value/label pair shown in a row of headline stats.
class _Stat {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;
}
