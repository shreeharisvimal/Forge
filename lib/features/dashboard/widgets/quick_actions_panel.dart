// Quick actions panel for the Forge dashboard.
//
// A row of tappable shortcuts to the app's main flows so the home screen
// is a launchpad as much as a summary.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/forge_design.dart';
import '../../../core/router/app_route_paths.dart';
import 'weight_log_sheet.dart';

/// The quick actions panel.
class QuickActionsPanel extends StatelessWidget {
  /// Creates the quick actions panel.
  const QuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction(
        label: 'Workout',
        icon: Icons.fitness_center_rounded,
        onTap: () => context.go(AppRoutePaths.workouts),
      ),
      _QuickAction(
        label: 'Log weight',
        icon: Icons.monitor_weight_outlined,
        onTap: () => showWeightLogSheet(context),
      ),
      _QuickAction(
        label: 'Calendar',
        icon: Icons.calendar_month_outlined,
        onTap: () => context.go(AppRoutePaths.calendar),
      ),
      _QuickAction(
        label: 'Splits',
        icon: Icons.view_week_outlined,
        onTap: () => context.push(AppRoutePaths.splits),
      ),
      _QuickAction(
        label: 'Progress',
        icon: Icons.insights_rounded,
        onTap: () => context.go(AppRoutePaths.progress),
      ),
    ];

    return GlassChartContainer(
      title: 'Quick actions',
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) SizedBox(width: AppSpacing.sm),
            Expanded(child: _QuickActionTile(action: actions[i])),
          ],
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return GlassPressable(
      onTap: action.onTap,
      semanticLabel: action.label,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: GlassContainer(
        width: double.infinity,
        padding: AppSpacing.md.all,
        borderRadius: BorderRadius.circular(AppRadius.small),
        decoration: GlassDecoration(
          color: colors.glassStrong,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, size: AppIconSize.medium, color: colors.primary),
            SizedBox(height: AppSpacing.xs),
            Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(color: colors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
