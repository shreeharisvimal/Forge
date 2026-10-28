// Progress feature screen for the Forge application.
//
// The analytics tab: a range-scoped dashboard of overview aggregates, the
// strength score and estimated-1RM trajectory, volume, training frequency,
// body weight, per-exercise analytics, achievements and the record timeline.
// Everything reads from [progressSnapshotProvider] so the tab stays live
// after any save from any feature.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/forge_design.dart';
import '../../services/providers.dart';
import '../progress/widgets/progress_achievements_section.dart';
import '../progress/widgets/progress_body_weight_section.dart';
import '../progress/widgets/progress_exercise_section.dart';
import '../progress/widgets/progress_frequency_heatmap.dart';
import '../progress/widgets/progress_overview_section.dart';
import '../progress/widgets/progress_pr_section.dart';
import '../progress/widgets/progress_strength_section.dart';
import '../progress/widgets/progress_volume_chart.dart';
import '../workout_session/domain/session_formatters.dart';
import 'domain/analytics_range.dart';
import 'providers/progress_providers.dart';

/// Progress screen — the analytics tab.
class ProgressScreen extends ConsumerWidget {
  /// Creates the progress screen.
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).forgeColors;
    final snapshot = ref.watch(progressSnapshotProvider);
    final unit = SessionWeightUnit.fromSettings(
      ref.watch(settingsProvider).weightUnit,
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            GlassAppBar(
              title: 'Progress',
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(
                  AppSpacing.giant + AppSpacing.lg,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: const _RangeSelector(),
                ),
              ),
            ),
            Expanded(
              child: snapshot.hasData
                  ? ListView(
                      padding: EdgeInsets.only(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        bottom: AppSpacing.giant * 2,
                      ),
                      children: [
                        ProgressOverviewSection(
                          snapshot: snapshot,
                          unit: unit,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        ProgressStrengthSection(
                          snapshot: snapshot,
                          unit: unit,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        ProgressVolumeChart(
                          snapshot: snapshot,
                          unit: unit,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        ProgressFrequencyHeatmap(snapshot: snapshot),
                        SizedBox(height: AppSpacing.lg),
                        ProgressBodyWeightSection(
                          snapshot: snapshot,
                          unit: unit,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        ProgressExerciseSection(
                          snapshot: snapshot,
                          unit: unit,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        const ProgressAchievementsSection(),
                        SizedBox(height: AppSpacing.lg),
                        ProgressPrSection(
                          snapshot: snapshot,
                          unit: unit,
                        ),
                      ],
                    )
                  : const _EmptyState(),
            ),
          ],
        ),
      ),
    );
  }
}

/// The analytics-window segmented control.
class _RangeSelector extends ConsumerWidget {
  const _RangeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(progressRangeProvider);
    final index = AnalyticsRange.all.indexOf(range);

    return GlassSegmentedControl(
      options: [for (final r in AnalyticsRange.all) r.label],
      selectedIndex: index < 0 ? AnalyticsRange.all.length - 1 : index,
      onChanged: (i) {
        ref.read(progressRangeProvider.notifier).state = AnalyticsRange.all[i];
      },
    );
  }
}

/// The empty state shown before any training or weigh-in data exists.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: GlassEmptyState(
          icon: Icons.insights_rounded,
          title: 'Your progress starts here',
          message:
              'Log workouts, track your lifts and weigh-ins to unlock '
              'analytics, charts and achievements.',
        ),
      ),
    );
  }
}
