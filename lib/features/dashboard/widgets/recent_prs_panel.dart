// Recent personal records panel for the Forge dashboard.
//
// Lists the latest three PRs with their previous best and the improvement
// made, celebrating new milestones.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../domain/dashboard_models.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard_formatters.dart';

/// The recent personal records panel.
class RecentPrsPanel extends ConsumerWidget {
  /// Creates the recent PRs panel.
  const RecentPrsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(recentPrsProvider);

    return GlassChartContainer(
      title: 'Personal records',
      subtitle: 'Latest breakthroughs',
      child: records.isEmpty
          ? _PrsEmpty()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < records.length; i++) ...[
                  if (i > 0) const GlassDivider(thickness: AppBorderWidth.thin),
                  _PrRow(entry: records[i]),
                ],
              ],
            ),
    );
  }
}

class _PrRow extends StatelessWidget {
  const _PrRow({required this.entry});

  final RecentPrEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: '${entry.exerciseName}, estimated one rep max '
          '${entry.estimatedOneRM.toStringAsFixed(1)}',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.exerciseName,
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  formatDay(entry.date),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassAnimatedNumber(
                value: entry.estimatedOneRM,
                decimals: 1,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSpacing.xxs),
              _ImprovementBadge(entry: entry),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImprovementBadge extends StatelessWidget {
  const _ImprovementBadge({required this.entry});

  final RecentPrEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    final improvement = entry.improvement;

    if (improvement == null) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        ),
        child: Text(
          'New',
          style: textTheme.labelSmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Text(
      '+${improvement.toStringAsFixed(1)}',
      style: textTheme.labelMedium?.copyWith(
        color: colors.success,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PrsEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: AppIconSize.doubleExtraLarge,
            color: colors.onSurfaceMuted,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'No personal records yet',
            style: textTheme.titleMedium?.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            'Every new best you set will show up here.',
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
