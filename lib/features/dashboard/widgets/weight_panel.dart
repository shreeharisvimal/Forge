// Current weight panel for the Forge dashboard.
//
// Shows the latest weigh-in, the change since the previous entry, the
// target weight and a 14-day mini trend chart. A quick action logs a new
// weigh-in and sets the goal.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../domain/dashboard_models.dart';
import '../providers/dashboard_providers.dart';
import 'weight_log_sheet.dart';

/// The weight panel with trend chart.
class WeightPanel extends ConsumerWidget {
  /// Creates the weight panel.
  const WeightPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).forgeColors;
    final data = ref.watch(weightPanelProvider);

    return GlassChartContainer(
      title: 'Weight',
      subtitle: 'Last 14 days',
      trailing: GlassIconButton(
        icon: Icons.add_rounded,
        tooltip: 'Log weight',
        semanticLabel: 'Log weight',
        onPressed: () => showWeightLogSheet(context),
      ),
      child: data.hasData
          ? _WeightContent(data: data)
          : _WeightEmpty(
              onLog: () => showWeightLogSheet(context),
              colors: colors,
            ),
    );
  }
}

class _WeightContent extends StatelessWidget {
  const _WeightContent({required this.data});

  final DashboardWeightData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    final latest = data.latest!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Current weight ${latest.toStringAsFixed(1)} ${data.unit}',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GlassAnimatedNumber(
                value: latest,
                decimals: 1,
                style: textTheme.headlineMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                formatter: (value) =>
                    '${value.toStringAsFixed(1)} ${data.unit}',
              ),
              if (data.delta != null) ...[
                SizedBox(width: AppSpacing.md),
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _DeltaLabel(delta: data.delta!),
                ),
              ],
            ],
          ),
        ),
        if (data.goal != null) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            'Goal ${data.goal!.toStringAsFixed(1)} ${data.unit}',
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
        ],
        if (data.trend.length >= 2) ...[
          SizedBox(height: AppSpacing.lg),
          _TrendChart(points: data.trend),
        ],
      ],
    );
  }
}

class _DeltaLabel extends StatelessWidget {
  const _DeltaLabel({required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final unit = Theme.of(context).textTheme;
    final direction = delta >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final color = delta > 0 ? colors.warning : colors.success;

    return Semantics(
      label: '${delta >= 0 ? 'Up' : 'Down'} ${delta.abs().toStringAsFixed(1)}'
          ' since the last entry',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(direction, size: AppIconSize.small, color: color),
          SizedBox(width: AppSpacing.xxs),
          Text(
            '${delta.abs().toStringAsFixed(1)} since last',
            style: unit.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});

  final List<WeightPoint> points;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;

    return SizedBox(
      height: AppSpacing.huge * 2.4,
      child: GlassContainer(
        width: double.infinity,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(AppRadius.small),
        decoration: GlassDecoration(
          color: colors.glassStrong,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: LineChart(
            _chartData(colors),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
  }

  LineChartData _chartData(ColorThemeExtension colors) {
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].weight),
    ];
    final color = colors.primary;

    return LineChartData(
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
            color: color.withValues(alpha: 0.14),
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
    );
  }
}

class _WeightEmpty extends StatelessWidget {
  const _WeightEmpty({required this.onLog, required this.colors});

  final VoidCallback onLog;
  final ColorThemeExtension colors;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monitor_weight_outlined,
            size: AppIconSize.doubleExtraLarge,
            color: colors.onSurfaceMuted,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'No weigh-ins yet',
            style: textTheme.titleMedium?.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            'Track your body weight to see the trend take shape.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          GlassButton(
            label: 'Log weight',
            icon: Icons.add_rounded,
            variant: GlassButtonVariant.tonal,
            onPressed: onLog,
          ),
        ],
      ),
    );
  }
}
