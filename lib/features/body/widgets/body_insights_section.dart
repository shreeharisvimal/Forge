// Body insights section for the Forge application.
//
// Renders the generated [BodyInsight] list as tinted glass cards, colored by
// kind. Pure presentation.
library;

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';
import '../../progress/domain/analytics_models.dart';
import '../domain/body_measurement_models.dart';

/// The insight cards.
class BodyInsightsSection extends StatelessWidget {
  /// Creates the insights section.
  const BodyInsightsSection({super.key, required this.insights});

  /// The insights to render.
  final List<BodyInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).forgeColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: AppIconSize.small,
              color: colors.secondary,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              'Insights',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: colors.onSurface),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        for (final insight in insights) ...[
          _InsightCard(insight: insight),
          SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// A single tinted insight card.
class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final BodyInsight insight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final (accent, background) = switch (insight.kind) {
      InsightKind.positive => (colors.success, colors.success.withValues(alpha: 0.12)),
      InsightKind.attention => (colors.danger, colors.danger.withValues(alpha: 0.12)),
      InsightKind.neutral => (colors.secondary, colors.secondary.withValues(alpha: 0.12)),
    };

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: AppSpacing.lg.all,
      decoration: GlassDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: const GlassBorder(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassContainer(
            width: AppSpacing.giant,
            height: AppSpacing.giant,
            borderRadius: BorderRadius.circular(AppRadius.small),
            decoration: GlassDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: const GlassBorder(),
            ),
            child: Center(
              child: Icon(
                _icon(insight.iconName),
                size: AppIconSize.small,
                color: accent,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  insight.message,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.onSurfaceMuted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon(String name) => switch (name) {
        'trend' => Icons.trending_up_rounded,
        'check' => Icons.check_circle_outline_rounded,
        'flag' => Icons.flag_outlined,
        'muscle' => Icons.fitness_center_rounded,
        'scale' => Icons.monitor_weight_outlined,
        'timer' => Icons.schedule_rounded,
        _ => Icons.lightbulb_outline_rounded,
      };
}
