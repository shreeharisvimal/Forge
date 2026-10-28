// Progress body-weight section for the Forge application.
//
// The weigh-in story for the selected window: latest reading with the change
// across the window, the window average / low / high, the active goal and a
// trend chart of every weigh-in.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/forge_design.dart';
import '../../workout_session/domain/session_formatters.dart';
import '../domain/analytics_models.dart';
import '../providers/progress_providers.dart';

/// The body-weight section for one [AnalyticsSnapshot].
class ProgressBodyWeightSection extends ConsumerWidget {
  /// Creates the body-weight section.
  const ProgressBodyWeightSection({
    super.key,
    required this.snapshot,
    required this.unit,
  });

  /// The snapshot to render.
  final AnalyticsSnapshot snapshot;

  /// The weight unit for display.
  final SessionWeightUnit unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).forgeColors;
    final weight = snapshot.weight;
    final goal = ref.watch(progressGoalWeightProvider);
    final unitLabel = unit == SessionWeightUnit.kg ? 'kg' : 'lb';

    return GlassChartContainer(
      title: 'Body weight',
      subtitle: snapshot.range.fullLabel,
      height: AppSpacing.huge * 3.4,
      child: !weight.hasData
          ? _WeightPlaceholder(colors: colors)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GlassAnimatedNumber(
                      value: weight.latest ?? 0,
                      decimals: 1,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                      formatter: (value) =>
                          '${value.toStringAsFixed(1)} $unitLabel',
                      semanticValue:
                          '${(weight.latest ?? 0).toStringAsFixed(1)} $unitLabel',
                    ),
                    if (weight.delta != null) ...[
                      SizedBox(width: AppSpacing.md),
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: _WeightDelta(delta: weight.delta!),
                      ),
                    ],
                  ],
                ),
                if (goal != null) ...[
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Goal ${goal.target.toStringAsFixed(1)} $unitLabel',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                  ),
                ],
                SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _MiniStat(
                      label: 'Average',
                      value: SessionFormatters.weight(weight.average ?? 0, unit),
                    ),
                    SizedBox(width: AppSpacing.lg),
                    _MiniStat(
                      label: 'Low',
                      value: SessionFormatters.weight(weight.min ?? 0, unit),
                    ),
                    SizedBox(width: AppSpacing.lg),
                    _MiniStat(
                      label: 'High',
                      value: SessionFormatters.weight(weight.max ?? 0, unit),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                Expanded(
                  child: weight.points.length >= 2
                      ? _WeightChart(points: weight.points, colors: colors)
                      : Center(
                          child: Text(
                            'One more weigh-in to draw your trend line.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceMuted,
                                ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

/// The signed change across the window.
class _WeightDelta extends StatelessWidget {
  const _WeightDelta({required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final direction =
        delta >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final color = delta > 0 ? colors.warning : colors.success;

    return Semantics(
      label: '${delta >= 0 ? 'Up' : 'Down'} ${delta.abs().toStringAsFixed(1)} '
          'across this window',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(direction, size: AppIconSize.small, color: color),
          SizedBox(width: AppSpacing.xxs),
          Text(
            '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// A compact label/value pair for the window summary.
class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceMuted),
        ),
        SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// The weigh-in trend line.
class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.points, required this.colors});

  final List<WeightPoint> points;
  final ColorThemeExtension colors;

  @override
  Widget build(BuildContext context) {
    final color = colors.primary;
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].weight),
    ];

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: points.length <= 8,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 1.5,
                strokeColor: colors.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colors.surfaceHigh,
          ),
        ),
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }
}

/// A compact placeholder when there are no weigh-ins in the window.
class _WeightPlaceholder extends StatelessWidget {
  const _WeightPlaceholder({required this.colors});

  final ColorThemeExtension colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monitor_weight_rounded,
            size: AppIconSize.extraLarge,
            color: colors.onSurfaceMuted,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'No weigh-ins in this window.',
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
