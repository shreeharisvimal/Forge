// Recent activity panel for the Forge dashboard.
//
// A feed of the latest workouts, weigh-ins, measurements and personal
// records, newest first.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../domain/dashboard_models.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard_formatters.dart';

/// The recent activity panel.
class RecentActivityPanel extends ConsumerWidget {
  /// Creates the recent activity panel.
  const RecentActivityPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(recentActivityProvider);

    return GlassChartContainer(
      title: 'Recent activity',
      subtitle: 'Your latest milestones',
      child: items.isEmpty
          ? _ActivityEmpty()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    const GlassDivider(thickness: AppBorderWidth.thin),
                  _ActivityRow(item: items[i]),
                ],
              ],
            ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();

    return Semantics(
      label: '${item.title}${item.subtitle == null ? '' : ', ${item.subtitle}'},'
          ' ${relativeDay(item.date, now)}',
      child: Row(
        children: [
          _ActivityIcon(kind: item.kind),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.subtitle != null) ...[
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    item.subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Text(
            relativeDay(item.date, now),
            style: textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityIcon extends StatelessWidget {
  const _ActivityIcon({required this.kind});

  final ActivityKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final (icon, color) = switch (kind) {
      ActivityKind.workout => (Icons.fitness_center_rounded, colors.primary),
      ActivityKind.weight => (Icons.monitor_weight_outlined, colors.secondary),
      ActivityKind.measurement => (Icons.straighten_rounded, colors.info),
      ActivityKind.record => (Icons.emoji_events_rounded, colors.warning),
    };

    return GlassContainer(
      width: AppSpacing.huge * 0.9,
      height: AppSpacing.huge * 0.9,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      decoration: GlassDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Center(
        child: Icon(icon, size: AppIconSize.small, color: color),
      ),
    );
  }
}

class _ActivityEmpty extends StatelessWidget {
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
            Icons.history_rounded,
            size: AppIconSize.doubleExtraLarge,
            color: colors.onSurfaceMuted,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Nothing here yet',
            style: textTheme.titleMedium?.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            'Workouts, weigh-ins and records will appear as you train.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
