// Progress record timeline section for the Forge application.
//
// Every personal record set within the selected window, newest first, as a
// connected timeline.
library;

import 'package:flutter/material.dart';

import '../../../../core/design/forge_design.dart';
import '../../prs/widgets/pr_timeline_tile.dart';
import '../../workout_session/domain/session_formatters.dart';
import '../domain/analytics_models.dart';
import 'progress_section_header.dart';

/// The record timeline for one [AnalyticsSnapshot].
class ProgressPrSection extends StatelessWidget {
  /// Creates the record timeline section.
  const ProgressPrSection({
    super.key,
    required this.snapshot,
    required this.unit,
  });

  /// The snapshot to render.
  final AnalyticsSnapshot snapshot;

  /// The weight unit for display.
  final SessionWeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final events = snapshot.prEvents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProgressSectionHeader(
          title: 'Records',
          subtitle: '${events.length} in window',
        ),
        SizedBox(height: AppSpacing.md),
        if (events.isEmpty)
          _EmptyRecords()
        else
          for (var i = 0; i < events.length; i++)
            PrTimelineTile(
              event: events[i],
              unit: unit,
              isFirst: i == 0,
              isLast: i == events.length - 1,
            ),
      ],
    );
  }
}

/// A compact empty card when no records were set in the window.
class _EmptyRecords extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return GlassContainer(
      width: double.infinity,
      padding: AppSpacing.xl.all,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      decoration: GlassDecoration(
        color: colors.glass,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: const GlassBorder(),
      ),
      child: Text(
        'No personal records in this window yet. '
        'Beat a best to add one.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceMuted,
            ),
      ),
    );
  }
}
