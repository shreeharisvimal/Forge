// Upcoming workout card for the Forge dashboard.
//
// Shows the next scheduled training day after today so the user always has
// something to look forward to.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/forge_design.dart';
import '../../../core/router/app_route_paths.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard_formatters.dart';

/// The next-session card.
class UpcomingWorkoutCard extends ConsumerWidget {
  /// Creates the upcoming workout card.
  const UpcomingWorkoutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingWorkoutProvider);
    final hasSplit = ref.watch(todayWorkoutProvider).hasSplit;
    final now = ref.watch(dashboardNowProvider);

    if (upcoming == null) {
      if (!hasSplit) return const SizedBox.shrink();
      return _RestUpCard(onPlan: () => context.push(AppRoutePaths.splits));
    }

    return _UpcomingCard(
      dayName: upcoming.day.name,
      focus: upcoming.day.focus,
      exerciseCount: upcoming.day.exercises.length,
      date: upcoming.date,
      now: now,
      onTap: () => context.push(AppRoutePaths.splits),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
    required this.dayName,
    required this.focus,
    required this.exerciseCount,
    required this.date,
    required this.now,
    required this.onTap,
  });

  final String dayName;
  final String focus;
  final int exerciseCount;
  final DateTime date;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return GlassPressable(
      onTap: onTap,
      semanticLabel: 'Up next: $dayName on ${formatDay(date)}',
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: AppSpacing.lg.all,
        decoration: GlassDecoration(
          color: colors.glass,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: const GlassBorder(),
        ),
        child: Row(
          children: [
            _UpcomingIcon(),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayName,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    _subtitle(),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Text(
              _whenLabel(),
              style: textTheme.labelLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle() {
    if (focus.isNotEmpty) return focus;
    return '$exerciseCount exercises';
  }

  String _whenLabel() {
    final day = DateTime(date.year, date.month, date.day);
    final base = DateTime(now.year, now.month, now.day);
    final difference = day.difference(base).inDays;
    if (difference == 1) return 'Tomorrow';
    return formatDay(date);
  }
}

class _UpcomingIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;

    return GlassContainer(
      width: AppSpacing.huge,
      height: AppSpacing.huge,
      borderRadius: BorderRadius.circular(AppRadius.large),
      decoration: GlassDecoration(
        color: colors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Center(
        child: Icon(
          Icons.schedule_rounded,
          size: AppIconSize.large,
          color: colors.primary,
        ),
      ),
    );
  }
}

class _RestUpCard extends StatelessWidget {
  const _RestUpCard({required this.onPlan});

  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: AppSpacing.lg.all,
      decoration: GlassDecoration(
        color: colors.glass,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: const GlassBorder(),
      ),
      child: Row(
        children: [
          _UpcomingIcon(),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rest up',
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  'No more sessions on this split cycle. Plan your next block.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          GlassButton(
            label: 'Plan',
            icon: Icons.view_week_outlined,
            variant: GlassButtonVariant.tonal,
            onPressed: onPlan,
          ),
        ],
      ),
    );
  }
}

