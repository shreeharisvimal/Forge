// Body feature screen for the Forge application.
//
// The measurement tab: headline deltas, trend chart, fat/lean composition,
// goals, insights and recent history. A floating action button logs a new
// measurement; tapping a history row edits that day. Reads everything from
// [bodySnapshotProvider] so the tab stays live after any save.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/forge_design.dart';
import '../../core/utils/dates.dart';
import '../../models/body_measurement.dart';
import '../progress/domain/analytics_range.dart';
import 'providers/body_providers.dart';
import 'widgets/body_comparison_section.dart';
import 'widgets/body_composition_section.dart';
import 'widgets/body_goals_section.dart';
import 'widgets/body_history_section.dart';
import 'widgets/body_insights_section.dart';
import 'widgets/body_measurement_form_sheet.dart';
import 'widgets/body_photo_gallery.dart';
import 'widgets/body_trend_chart.dart';

/// The body measurements tab.
class BodyScreen extends ConsumerWidget {
  /// Creates the body screen.
  const BodyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(bodySnapshotProvider);
    final settings = ref.watch(bodySettingsProvider);
    final colors = Theme.of(context).forgeColors;
    final history = snapshot.measurements.reversed.toList();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            GlassAppBar(
              title: 'Body',
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
                  child: _RangeSelector(),
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
                        _latestBlock(context, snapshot.measurements.length),
                        SizedBox(height: AppSpacing.lg),
                        BodyComparisonSection(
                          entries: snapshot.comparisons,
                          settings: settings,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        const BodyTrendChart(),
                        SizedBox(height: AppSpacing.lg),
                        const BodyCompositionSection(),
                        SizedBox(height: AppSpacing.lg),
                        const BodyGoalsSection(),
                        SizedBox(height: AppSpacing.lg),
                        BodyInsightsSection(insights: snapshot.insights),
                        if (snapshot.insights.isNotEmpty)
                          SizedBox(height: AppSpacing.lg),
                        if (snapshot.latest?.photos.isNotEmpty ?? false)
                          BodyPhotoGallery(
                            photos: snapshot.latest!.photos,
                            photoThumbs: snapshot.latest!.photoThumbs,
                          ),
                        if (snapshot.latest?.photos.isNotEmpty ?? false)
                          SizedBox(height: AppSpacing.lg),
                        BodyHistorySection(
                          measurements: history,
                          settings: settings,
                          onEdit: (measurement) =>
                              _editMeasurement(context, ref, measurement),
                        ),
                      ],
                    )
                  : _EmptyState(
                      onLog: () => _logMeasurement(context, ref),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: GlassFAB(
        icon: Icons.add_rounded,
        label: 'Log',
        semanticLabel: 'Log measurements',
        tooltip: 'Log measurements',
        onPressed: () => _logMeasurement(context, ref),
      ),
    );
  }

  Widget _latestBlock(BuildContext context, int count) {
    return GlassContainer(
      padding: AppSpacing.lg.all,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      decoration: GlassDecoration(
        gradient: GlassGradient(
          colors: AppGradients.primaryToSecondary,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: const GlassBorder(),
      ),
      child: Row(
        children: [
          Icon(
            Icons.straighten_rounded,
            size: AppIconSize.medium,
            color: Theme.of(context).forgeColors.onPrimary,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              count == 1 ? '1 measurement logged' : '$count measurements logged',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).forgeColors.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logMeasurement(BuildContext context, WidgetRef ref) async {
    final now = ref.read(bodyNowProvider);
    await showBodyMeasurementFormSheet(context, date: dateOnly(now));
  }

  Future<void> _editMeasurement(
    BuildContext context,
    WidgetRef ref,
    BodyMeasurement measurement,
  ) async {
    await showBodyMeasurementFormSheet(
      context,
      date: measurement.date,
      initial: measurement,
    );
  }
}

/// The analytics-window segmented control.
class _RangeSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(bodyRangeProvider);
    final index = AnalyticsRange.all.indexOf(range);

    return GlassSegmentedControl(
      options: [for (final r in AnalyticsRange.all) r.label],
      selectedIndex: index < 0 ? AnalyticsRange.all.length - 1 : index,
      onChanged: (i) {
        ref.read(bodyRangeProvider.notifier).state = AnalyticsRange.all[i];
      },
    );
  }
}

/// The empty state shown before the first measurement.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onLog});

  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: GlassEmptyState(
          icon: Icons.straighten_rounded,
          title: 'Log your first measurements',
          message:
              'Track weight, waist, hip, girths and body fat to see '
              'comparisons, trends and insights take shape.',
          action: GlassButton(
            label: 'Log measurements',
            icon: Icons.add_rounded,
            onPressed: onLog,
          ),
        ),
      ),
    );
  }
}
