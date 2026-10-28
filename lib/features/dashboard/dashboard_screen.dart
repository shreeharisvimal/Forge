// Dashboard feature screen for the Forge application.
//
// The home tab: a scrollable, glass dashboard that greets the user, shows
// today's workout and recovery state, summarizes the week, celebrates
// records, offers quick actions and ends with the quote of the day and a
// recent activity feed. Every panel watches only its own providers so
// edits elsewhere never rebuild the whole screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/forge_design.dart';
import 'widgets/dashboard_greeting.dart';
import 'widgets/motivation_panel.dart';
import 'widgets/quick_actions_panel.dart';
import 'widgets/recent_activity_panel.dart';
import 'widgets/recent_prs_panel.dart';
import 'widgets/recovery_panel.dart';
import 'widgets/today_workout_card.dart';
import 'widgets/upcoming_workout_card.dart';
import 'widgets/weekly_summary_panel.dart';
import 'widgets/weight_panel.dart';

/// Home dashboard screen — the first tab in the navigation shell.
class DashboardScreen extends ConsumerWidget {
  /// Creates the dashboard screen.
  const DashboardScreen({super.key});

  static const Duration _step = Duration(milliseconds: 60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: true,
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          children: [
            _section(0, child: const DashboardGreeting()),
            _section(1, child: const TodayWorkoutCard()),
            _section(2, child: const WeightPanel()),
            _section(3, child: const RecoveryPanel()),
            _section(4, child: const WeeklySummaryPanel()),
            _section(5, child: const RecentPrsPanel()),
            _section(6, child: const UpcomingWorkoutCard()),
            _section(7, child: const QuickActionsPanel()),
            _section(8, child: const MotivationPanel()),
            _section(9, child: const RecentActivityPanel()),
          ],
        ),
      ),
    );
  }

  Widget _section(int index, {required Widget child}) {
    return GlassAnimated(
      entrance: GlassEntrance.slide,
      delay: _step * index,
      child: Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.lg),
        child: child,
      ),
    );
  }
}
