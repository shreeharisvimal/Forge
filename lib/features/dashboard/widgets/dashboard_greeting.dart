// Greeting header for the Forge dashboard.
//
// Shows a time-aware greeting and the full date, animating in with a
// springy entrance on mount.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard_formatters.dart';

/// The time-aware greeting block at the top of the dashboard.
class DashboardGreeting extends ConsumerWidget {
  /// Creates the greeting block.
  const DashboardGreeting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    final now = ref.watch(dashboardNowProvider);

    final greeting = _greetingForHour(now.hour);

    return GlassAnimated.spring(
      child: Semantics(
        header: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: textTheme.displaySmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppSpacing.xxs),
            Text(
              formatFullDate(now),
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _greetingForHour(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}
