// Progress volume chart for the Forge application.
//
// A bar chart of training volume (weight x reps) bucketed across the
// selected window, with per-bucket set counts in the tooltip.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/forge_design.dart';
import '../../workout_session/domain/session_formatters.dart';
import '../domain/analytics_models.dart';

/// The volume bar chart for one [AnalyticsSnapshot].
class ProgressVolumeChart extends StatelessWidget {
  /// Creates the volume chart.
  const ProgressVolumeChart({
    super.key,
    required this.snapshot,
    required this.unit,
  });

  /// The snapshot to chart.
  final AnalyticsSnapshot snapshot;

  /// The weight unit for display.
  final SessionWeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final buckets = snapshot.volumeBuckets;
    final totalVolume = buckets.fold<double>(0, (sum, bucket) => sum + bucket.volume);

    return GlassChartContainer(
      title: 'Volume',
      subtitle: snapshot.range.fullLabel,
      height: AppSpacing.huge * 2.6,
      child: buckets.isEmpty || totalVolume <= 0
          ? _VolumePlaceholder(colors: colors)
          : _VolumeBars(buckets: buckets, unit: unit, colors: colors),
    );
  }
}

/// The bar chart body.
class _VolumeBars extends StatelessWidget {
  const _VolumeBars({
    required this.buckets,
    required this.unit,
    required this.colors,
  });

  final List<VolumeBucket> buckets;
  final SessionWeightUnit unit;
  final ColorThemeExtension colors;

  @override
  Widget build(BuildContext context) {
    final color = colors.primary;
    final maxVolume = buckets
        .fold<double>(0, (max, bucket) => bucket.volume > max ? bucket.volume : max);
    final safeMax = maxVolume > 0 ? maxVolume : 1.0;
    final labelStep = (buckets.length / 6).ceil().clamp(1, 1 << 30);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: safeMax * 1.15,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => colors.surfaceHigh,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final bucket = buckets[group.x];
              return BarTooltipItem(
                '${bucket.label}\n'
                '${SessionFormatters.volume(rod.toY, unit)}'
                ' · ${bucket.sets} ${bucket.sets == 1 ? 'set' : 'sets'}',
                TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: AppSpacing.xl,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= buckets.length) {
                  return const SizedBox.shrink();
                }
                final show = index % labelStep == 0 ||
                    index == buckets.length - 1;
                if (!show) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Text(
                    buckets[index].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colors.outline.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < buckets.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: buckets[i].volume,
                  color: color,
                  width: 12,
                  borderRadius: BorderRadius.circular(AppRadius.extraSmall),
                ),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }
}

/// A compact placeholder when there is no volume to chart.
class _VolumePlaceholder extends StatelessWidget {
  const _VolumePlaceholder({required this.colors});

  final ColorThemeExtension colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.layers_rounded,
            size: AppIconSize.extraLarge,
            color: colors.onSurfaceMuted,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Move some weight to see your volume take shape.',
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
