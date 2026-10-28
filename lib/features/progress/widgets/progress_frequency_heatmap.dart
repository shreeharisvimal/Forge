// Progress frequency heatmap for the Forge application.
//
// A GitHub-style training-frequency grid: one row per week (Monday first),
// one cell per day, filled by the day's normalized set count. Future days
// render as muted placeholders.
library;

import 'package:flutter/material.dart';

import '../../../../core/design/forge_design.dart';
import '../domain/analytics_models.dart';

/// The frequency heatmap for one [AnalyticsSnapshot].
class ProgressFrequencyHeatmap extends StatelessWidget {
  /// Creates the frequency heatmap.
  const ProgressFrequencyHeatmap({
    super.key,
    required this.snapshot,
  });

  /// The snapshot to render.
  final AnalyticsSnapshot snapshot;

  static const List<String> _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final heatmap = snapshot.heatmap;
    final days = heatmap.totalWorkouts;

    return GlassChartContainer(
      title: 'Frequency',
      subtitle: '$days active ${days == 1 ? 'day' : 'days'} · '
          '${snapshot.range.fullLabel}',
      height: AppSpacing.lg +
          AppSpacing.xxs +
          heatmap.weeks.length * (AppSpacing.lg + AppSpacing.xxs) +
          AppSpacing.md +
          AppSpacing.lg,
      child: heatmap.weeks.isEmpty
          ? _HeatmapPlaceholder(colors: colors)
          : _HeatmapGrid(
              heatmap: heatmap,
              colors: colors,
              maxSets: heatmap.maxSets,
            ),
    );
  }
}

/// The weekday header, day grid and intensity legend.
class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({
    required this.heatmap,
    required this.colors,
    required this.maxSets,
  });

  final FrequencyHeatmapData heatmap;
  final ColorThemeExtension colors;
  final int maxSets;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WeekdayHeader(colors: colors),
        SizedBox(height: AppSpacing.xxs),
        for (final week in heatmap.weeks)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.xxs),
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(child: _dayCell(week.length > i ? week[i] : null)),
              ],
            ),
          ),
        SizedBox(height: AppSpacing.md),
        _IntensityLegend(colors: colors),
      ],
    );
  }

  Widget _dayCell(FrequencyDay? day) {
    final trained = day != null && day.trained;
    final intensity = day?.intensity ?? 0;
    final color = trained
        ? colors.primary.withValues(alpha: 0.16 + 0.84 * intensity)
        : colors.glassStrong.withValues(alpha: 0.45);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Semantics(
        label: day == null
            ? 'No day'
            : day.trained
                ? '${day.sets} sets'
                : 'No training',
        child: Container(
          height: AppSpacing.lg,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.extraSmall),
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// The M/T/W/T/F/S/S header row.
class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.colors});

  final ColorThemeExtension colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Text(
              ProgressFrequencyHeatmap._weekdays[i],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
            ),
          ),
      ],
    );
  }
}

/// The "less -> more" intensity legend.
class _IntensityLegend extends StatelessWidget {
  const _IntensityLegend({required this.colors});

  final ColorThemeExtension colors;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Less',
          style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceMuted),
        ),
        SizedBox(width: AppSpacing.xs),
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              width: AppSpacing.sm,
              height: AppSpacing.sm,
              decoration: BoxDecoration(
                color: colors.primary
                    .withValues(alpha: 0.16 + 0.21 * i),
                borderRadius: BorderRadius.circular(AppRadius.extraSmall),
              ),
            ),
          ),
        SizedBox(width: AppSpacing.xs),
        Text(
          'More',
          style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceMuted),
        ),
      ],
    );
  }
}

/// A compact placeholder when there are no sessions to render.
class _HeatmapPlaceholder extends StatelessWidget {
  const _HeatmapPlaceholder({required this.colors});

  final ColorThemeExtension colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_view_month_rounded,
            size: AppIconSize.extraLarge,
            color: colors.onSurfaceMuted,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Training frequency will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
          ),
        ],
      ),
    );
  }
}
