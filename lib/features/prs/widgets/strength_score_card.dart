// Strength score card for the Forge application.
//
// The headline of the PR dashboard: the composite 0-100 Forge score with the
// four driving factors and, when inputs allow, the DOTS / Wilks points.
library;

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';
import '../../workout_session/domain/session_formatters.dart';
import '../domain/strength_score.dart';

/// A glass card presenting the composite [StrengthScore].
class StrengthScoreCard extends StatelessWidget {
  /// Creates a strength score card.
  const StrengthScoreCard({
    super.key,
    required this.score,
    required this.unit,
  });

  /// The computed strength score.
  final StrengthScore score;

  /// The weight unit for display.
  final SessionWeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;

    if (!score.hasData) {
      return GlassCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: GlassDecoration(
          color: colors.glass,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: const GlassBorder(),
        ),
        child: Column(
          children: [
            Icon(Icons.insights_rounded,
                size: AppIconSize.extraLarge, color: colors.onSurfaceMuted),
            SizedBox(height: AppSpacing.md),
            Text(
              'Log your first workout to unlock your strength score.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
            ),
          ],
        ),
      );
    }

    final rows = <_FactorRow>[
      _FactorRow(
        label: 'Total estimated 1RM',
        value: SessionFormatters.volume(score.totalOneRM, unit),
        fraction: (score.totalOneRM / 1500).clamp(0.0, 1.0),
      ),
      _FactorRow(
        label: 'Best lift to body weight',
        value: score.bodyweightRatio > 0
            ? '${score.bodyweightRatio.toStringAsFixed(2)}x'
            : '—',
        fraction: (score.bodyweightRatio / 2).clamp(0.0, 1.0),
      ),
      _FactorRow(
        label: 'Lifetime volume',
        value: SessionFormatters.volume(score.lifetimeVolume, unit),
        fraction: (score.lifetimeVolume / 100000).clamp(0.0, 1.0),
      ),
      _FactorRow(
        label: 'Frequency',
        value: '${score.workoutsPerWeek.toStringAsFixed(1)}/wk',
        fraction: (score.workoutsPerWeek / 5).clamp(0.0, 1.0),
      ),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: GlassDecoration(
        color: colors.glass,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: const GlassBorder(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strength score',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      '${score.exercises} '
                      '${score.exercises == 1 ? 'exercise' : 'exercises'} tracked',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceMuted,
                          ),
                    ),
                  ],
                ),
              ),
              GlassAnimatedNumber(
                value: score.overall,
                decimals: 0,
                style: ForgeTypography.numberStyle(
                  fontSize: 40,
                  color: colors.primary,
                ),
                semanticValue: score.overall.round().toString(),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          for (final row in rows) ...[
            row,
            if (row != rows.last) SizedBox(height: AppSpacing.md),
          ],
          if (score.dots != null || score.wilks != null) ...[
            SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (score.dots != null)
                  _ScoreChip(label: 'DOTS', value: score.dots!.round().toString()),
                if (score.wilks != null)
                  _ScoreChip(
                    label: 'Wilks',
                    value: score.wilks!.toStringAsFixed(1),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A single labeled progress factor inside the score card.
class _FactorRow extends StatelessWidget {
  const _FactorRow({
    required this.label,
    required this.value,
    required this.fraction,
  });

  final String label;
  final String value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 72,
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

/// A small stat chip for a secondary score system.
class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: GlassDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        border: GlassBorder(color: colors.primary.withValues(alpha: 0.35)),
      ),
      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
