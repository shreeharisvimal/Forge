// Progress strength section for the Forge application.
//
// The strength story for the selected window: the composite 0-100 strength
// score across the whole history, then the total estimated-1RM trajectory
// across the tracked exercises in this window.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/forge_design.dart';
import '../../../../core/utils/dates.dart';
import '../../prs/providers/pr_providers.dart';
import '../../prs/widgets/strength_score_card.dart';
import '../../workout_session/domain/session_formatters.dart';
import '../domain/analytics_models.dart';

/// The strength section for one [AnalyticsSnapshot].
class ProgressStrengthSection extends ConsumerWidget {
  /// Creates the strength section.
  const ProgressStrengthSection({
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
    final strength = snapshot.strength;
    final series = _totalSeries(strength.trajectories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StrengthScoreCard(
          score: ref.watch(strengthScoreProvider),
          unit: unit,
        ),
        SizedBox(height: AppSpacing.lg),
        GlassChartContainer(
          title: 'Estimated 1RM',
          subtitle:
              'Total ${SessionFormatters.weightWithUnit(strength.totalOneRM, unit)}'
              ' · Best ${SessionFormatters.weightWithUnit(strength.bestOneRM, unit)}',
          height: AppSpacing.huge * 2.4,
          child: series.length >= 2
              ? _TrajectoryChart(series: series, colors: colors, unit: unit)
              : _ChartPlaceholder(
                  icon: Icons.show_chart_rounded,
                  message: 'Keep lifting to reveal your strength trend.',
                ),
        ),
      ],
    );
  }

  /// The window's total estimated 1RM per day, merged across exercises.
  List<({DateTime date, double value})> _totalSeries(
    List<OneRmTrajectory> trajectories,
  ) {
    final byDate = <DateTime, double>{};
    for (final trajectory in trajectories) {
      for (final point in trajectory.points) {
        final day = dateOnly(point.date);
        byDate[day] = (byDate[day] ?? 0) + point.value;
      }
    }
    final dates = byDate.keys.toList()..sort();
    return [
      for (final date in dates) (date: date, value: byDate[date]!),
    ];
  }
}

/// A line chart of the total estimated-1RM series.
class _TrajectoryChart extends StatelessWidget {
  const _TrajectoryChart({
    required this.series,
    required this.colors,
    required this.unit,
  });

  final List<({DateTime date, double value})> series;
  final ColorThemeExtension colors;
  final SessionWeightUnit unit;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final color = colors.primary;
    final spots = [
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].value),
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
              show: series.length <= 8,
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
              color: color.withValues(alpha: 0.14),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _niceInterval(series),
          getDrawingHorizontalLine: (value) => FlLine(
            color: colors.outline.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: AppSpacing.xl,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index == 0 ||
                    index == series.length - 1 ||
                    (series.length > 8 && index == series.length ~/ 2)) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text(
                      _dateLabel(series[index].date),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceMuted,
                          ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colors.surfaceHigh,
            getTooltipItems: (touchedSpots) => [
              for (final spot in touchedSpots)
                LineTooltipItem(
                  '${_dateLabel(series[spot.x.round()].date)}\n'
                  '${SessionFormatters.weight(spot.y, unit)}',
                  TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  double _niceInterval(List<({DateTime date, double value})> points) {
    final values = points.map((point) => point.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs();
    if (range == 0) return 10;
    return (range / 4).ceilToDouble().clamp(1, 1000).toDouble();
  }

  String _dateLabel(DateTime date) => '${_months[date.month - 1]} ${date.day}';
}

/// A compact empty/placeholder block inside a chart container.
class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.extraLarge, color: colors.onSurfaceMuted),
          SizedBox(height: AppSpacing.sm),
          Text(
            message,
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
