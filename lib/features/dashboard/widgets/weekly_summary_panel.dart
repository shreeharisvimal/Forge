// Weekly summary panel for the Forge dashboard.
//
// Six animated stat tiles covering the current training week: streak,
// workouts, sets, reps, volume and minutes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/forge_design.dart';
import '../../../core/router/app_route_paths.dart';
import '../domain/dashboard_models.dart';
import '../providers/dashboard_providers.dart';

/// The weekly summary panel.
class WeeklySummaryPanel extends ConsumerWidget {
  /// Creates the weekly summary panel.
  const WeeklySummaryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(weeklySummaryProvider);

    return GlassChartContainer(
      title: 'This week',
      subtitle: 'Monday through today',
      child: summary.hasData
          ? _SummaryGrid(summary: summary)
          : _SummaryEmpty(
              onStart: () => context.go(AppRoutePaths.workouts),
            ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final WeeklySummaryData summary;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(
        label: 'Streak',
        value: summary.streak.toDouble(),
        suffix: summary.streak == 1 ? ' day' : ' days',
      ),
      _StatTile(label: 'Workouts', value: summary.workouts.toDouble()),
      _StatTile(label: 'Sets', value: summary.sets.toDouble()),
      _StatTile(label: 'Reps', value: summary.reps.toDouble()),
      _StatTile(label: 'Volume', value: summary.volume, decimals: 0),
      _StatTile(label: 'Minutes', value: summary.minutes.toDouble()),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (var column = 0; column < 3; column++) ...[
                if (column > 0) SizedBox(width: AppSpacing.md),
                Expanded(child: tiles[row * 3 + column]),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.suffix = '',
    this.decimals = 0,
  });

  final String label;
  final double value;
  final String suffix;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return GlassContainer(
      width: double.infinity,
      padding: AppSpacing.md.all,
      borderRadius: BorderRadius.circular(AppRadius.small),
      decoration: GlassDecoration(
        color: colors.glassStrong,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
          SizedBox(height: AppSpacing.xxs),
          GlassAnimatedNumber(
            value: value,
            decimals: decimals,
            style: textTheme.headlineSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
            formatter: (animated) =>
                '${animated.toStringAsFixed(decimals)}$suffix',
          ),
        ],
      ),
    );
  }
}

class _SummaryEmpty extends StatelessWidget {
  const _SummaryEmpty({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'No sessions this week yet. Your streak is waiting.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.lg),
          GlassButton(
            label: 'Start',
            icon: Icons.play_arrow_rounded,
            variant: GlassButtonVariant.tonal,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}
