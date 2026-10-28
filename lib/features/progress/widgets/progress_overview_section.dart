// Progress overview section for the Forge application.
//
// The headline aggregate grid: workouts, volume, sets and personal records
// for the selected window, each with its change versus the previous window
// of equal length. Responsive: two cards per row on phones, more on larger
// screens.
library;

import 'package:flutter/material.dart';

import '../../../../core/design/forge_design.dart';
import '../../workout_session/domain/session_formatters.dart';
import '../domain/analytics_models.dart';
import 'progress_section_header.dart';

/// The overview aggregate grid for one [AnalyticsSnapshot].
class ProgressOverviewSection extends StatelessWidget {
  /// Creates the overview section.
  const ProgressOverviewSection({
    super.key,
    required this.snapshot,
    required this.unit,
  });

  /// The snapshot to summarize.
  final AnalyticsSnapshot snapshot;

  /// The weight unit for display.
  final SessionWeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final overview = snapshot.overview;
    final columns = Responsive.columns(
      context,
      compact: 2,
      medium: 3,
      expanded: 4,
    );
    final spacing = AppSpacing.md;

    final cards = [
      GlassStatisticCard(
        title: 'Workouts',
        value: overview.workouts.toDouble(),
        decimals: 0,
        icon: Icons.fitness_center_rounded,
        delta: overview.workoutsDelta,
        deltaLabel: _deltaLabel(overview.workoutsDelta, 'vs prior'),
      ),
      GlassStatisticCard(
        title: 'Volume',
        value: overview.volume,
        decimals: 0,
        valueFormatter: (value) => SessionFormatters.volume(value, unit),
        delta: overview.volumeDelta,
        deltaLabel: _deltaLabel(overview.volumeDelta, 'vs prior'),
      ),
      GlassStatisticCard(
        title: 'Sets',
        value: overview.sets.toDouble(),
        decimals: 0,
        icon: Icons.format_list_numbered_rounded,
        delta: overview.setsDelta,
        deltaLabel: _deltaLabel(overview.setsDelta, 'vs prior'),
      ),
      GlassStatisticCard(
        title: 'Records',
        value: overview.prs.toDouble(),
        decimals: 0,
        icon: Icons.bolt_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProgressSectionHeader(
          title: 'Overview',
          subtitle: snapshot.range.fullLabel,
        ),
        SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - spacing * (columns - 1)) /
                columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final card in cards)
                  SizedBox(width: itemWidth, child: card),
              ],
            );
          },
        ),
      ],
    );
  }

  /// A signed percentage label, e.g. "+25% vs prior".
  String _deltaLabel(double? delta, String suffix) {
    if (delta == null) return suffix;
    final percent = (delta * 100).round();
    return '${percent >= 0 ? '+' : ''}$percent% $suffix';
  }
}
