// Body trend chart for the Forge application.
//
// The selected field's time series inside a [GlassChartContainer], with a
// field selector and the window's min/max/delta summary. Rendered through
// fl_chart following the dashboard weight-panel pattern.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../../../models/settings_model.dart';
import '../domain/body_measurement_fields.dart';
import '../domain/body_measurement_models.dart';
import '../presentation/body_formatters.dart';
import '../providers/body_providers.dart';

/// The trend chart with a field selector.
class BodyTrendChart extends ConsumerWidget {
  /// Creates the trend chart.
  const BodyTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(bodyChartTrendProvider);
    final settings = ref.watch(bodySettingsProvider);
    final colors = Theme.of(context).forgeColors;

    return GlassChartContainer(
      title: trend?.field.label ?? 'Trend',
      subtitle: trend?.hasData == true
          ? _summaryLabel(trend!, settings)
          : 'Track a measurement to see the trend',
      trailing: GlassIconButton(
        icon: Icons.swap_vert_rounded,
        tooltip: 'Change field',
        semanticLabel: 'Change chart field',
        onPressed: () => _selectField(context, ref),
      ),
      height: AppSpacing.huge * 2.6,
      child: trend?.hasData == true
          ? _TrendChartBody(trend: trend!, settings: settings)
          : Center(
              child: Icon(
                Icons.show_chart_rounded,
                size: AppIconSize.doubleExtraLarge,
                color: colors.onSurfaceMuted,
              ),
            ),
    );
  }

  String _summaryLabel(BodyFieldTrend trend, SettingsModel settings) {
    final field = trend.field;
    final delta = trend.delta;
    if (delta == null) {
      return '${trend.points.length} entries';
    }
    return '${trend.points.length} entries · '
        '${BodyFormatters.deltaWithUnit(delta, field, settings)} over window';
  }

  Future<void> _selectField(BuildContext context, WidgetRef ref) async {
    final selected = await GlassBottomSheet.show<BodyField>(
      context,
      maxChildSize: 0.7,
      builder: (context) => _FieldPickerSheet(
        current: ref.read(bodyChartFieldProvider),
      ),
    );
    if (selected != null && context.mounted) {
      ref.read(bodyChartFieldProvider.notifier).state = selected;
    }
  }
}

/// The line chart body for one field trend.
class _TrendChartBody extends StatelessWidget {
  const _TrendChartBody({required this.trend, required this.settings});

  final BodyFieldTrend trend;
  final SettingsModel settings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final spots = [
      for (var i = 0; i < trend.points.length; i++)
        FlSpot(
          i.toDouble(),
          BodyFormatters.displayValue(trend.points[i].value, trend.field, settings),
        ),
    ];
    final color = colors.primary;

    return Padding(
      padding: EdgeInsets.only(
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: trend.points.length <= 8,
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
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => colors.surfaceHigh,
              getTooltipItems: (touchedSpots) => [
                for (final spot in touchedSpots)
                  LineTooltipItem(
                    BodyFormatters.valueWithUnit(
                      spot.y,
                      trend.field,
                      settings,
                    ),
                    TextStyle(color: colors.onSurface),
                  ),
              ],
            ),
          ),
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

/// The bottom sheet listing every chartable field.
class _FieldPickerSheet extends StatelessWidget {
  const _FieldPickerSheet({required this.current});

  final BodyField current;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Chart field',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final field in BodyField.chartableFields)
                GlassChip(
                  label: field.label,
                  selected: field == current,
                  onTap: () => Navigator.of(context).pop(field),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
