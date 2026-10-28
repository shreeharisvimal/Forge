// Summary stage of the workout session.
//
// Shows the finished workout's numbers, achievements and recovery guidance,
// with share-to-clipboard and a Done action that discards the in-progress
// state and pops back to the dashboard.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/forge_design.dart';
import '../../../../core/overlays/forge_overlays.dart';
import '../../../../core/services/share/share_service.dart';
import '../../../../features/prs/presentation/pr_celebration_host.dart';
import '../../../../features/prs/providers/pr_providers.dart';
import '../../../../features/prs/widgets/glass_pr_card.dart';
import '../../../../features/prs/widgets/strength_score_card.dart';
import '../../../../services/providers.dart';
import '../../domain/session_calculations.dart';
import '../../domain/session_formatters.dart';
import '../../domain/session_models.dart';
import '../../domain/session_recovery.dart';
import '../../domain/session_share.dart';
import '../../providers/session_providers.dart';

/// The summary stage content.
class SummaryStage extends ConsumerWidget {
  /// Creates the summary stage.
  const SummaryStage({super.key, required this.session});

  /// The finished session.
  final ActiveSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).forgeColors;
    final unit = SessionWeightUnit.fromSettings(
      ref.watch(settingsProvider).weightUnit,
    );
    final bodyWeightKg =
        ref.watch(weightRepositoryProvider).latest()?.weight ?? 0;
    final now = ref.watch(sessionNowProvider);
    final stats = SessionCalculations.statsFor(
      session,
      now: now,
      bodyWeightKg: bodyWeightKg,
    );
    final achievements = SessionCalculations.achievements(
      stats: stats,
      bodyWeightKg: bodyWeightKg,
    );
    final muscleGroups = _muscleGroups(ref);
    final recovery = SessionRecoveryCalculator.compute(muscleGroups);
    final controller = ref.read(activeSessionProvider.notifier);
    final records = ref.watch(prCelebrationProvider);
    final strength = ref.watch(strengthScoreProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const PrCelebrationHost(),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Hero(session: session, stats: stats, unit: unit),
                SizedBox(height: AppSpacing.lg),
                _StatsGrid(stats: stats, unit: unit),
                if (records.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Records',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  for (final event in records)
                    GlassPrCard(event: event, unit: unit, highlight: true),
                ],
                if (achievements.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Achievements',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  for (final achievement in achievements)
                    _AchievementCard(achievement: achievement),
                ],
                if (recovery.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Recovery',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: GlassDecoration(
                      color: colors.glass,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: const GlassBorder(),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final entry in recovery)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.self_improvement_rounded,
                                  size: AppIconSize.small,
                                  color: colors.primary,
                                ),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    entry.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: colors.onSurface),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Strength',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: AppSpacing.md),
                StrengthScoreCard(score: strength, unit: unit),
                SizedBox(height: AppSpacing.xxl),
                GlassButton(
                  label: 'Share summary',
                  icon: Icons.ios_share_rounded,
                  variant: GlassButtonVariant.tonal,
                  expanded: true,
                  onPressed: () => _share(context, ref, unit, stats),
                ),
                SizedBox(height: AppSpacing.sm),
                GlassButton(
                  label: 'Done',
                  icon: Icons.check_rounded,
                  size: GlassButtonSize.large,
                  expanded: true,
                  onPressed: () async {
                    await controller.abandon();
                    if (context.mounted) context.pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The muscle group labels of the session's exercises, resolved from the
  /// exercise library (unknown ids are skipped).
  List<String> _muscleGroups(WidgetRef ref) {
    final byId = {for (final exercise in ref.watch(exerciseRepositoryProvider).all()) exercise.id: exercise};
    final groups = <String>[];
    for (final performed in session.content.exercises) {
      final library = byId[performed.exerciseId];
      final group = library?.muscleGroup;
      if (group != null) groups.add(group);
    }
    return groups;
  }

  Future<void> _share(
    BuildContext context,
    WidgetRef ref,
    SessionWeightUnit unit,
    SessionStats stats,
  ) async {
    final startedAt = session.content.startedAt ?? DateTime.now();
    final text = SessionShareText.build(
      sessionName: session.name,
      date: startedAt,
      duration: Duration(seconds: stats.durationSeconds),
      exerciseCount: stats.exercises,
      setCount: stats.sets,
      volumeKg: stats.volume,
      repCount: stats.reps,
      calories: stats.calories,
      unit: unit,
    );
    final result = await ref
        .read(shareServiceProvider)
        .share(ForgeSharePayload(title: session.name, text: text));
    if (!context.mounted) return;
    result.when(
      success: (_) => context.showSuccess('Workout summary copied to clipboard'),
      failure: (_) => context.showError('Could not copy the workout summary'),
    );
  }
}

/// The headline of the summary: name, duration, set and rep counts.
class _Hero extends StatelessWidget {
  const _Hero({required this.session, required this.stats, required this.unit});

  final ActiveSession session;
  final SessionStats stats;
  final SessionWeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: GlassDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: GlassBorder(color: colors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassContainer(
                width: AppSpacing.huge,
                height: AppSpacing.huge,
                borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                decoration: GlassDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                  border: const GlassBorder(),
                ),
                child: Center(
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: AppIconSize.medium,
                    color: colors.primary,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name.isEmpty ? 'Workout complete' : session.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      SessionFormatters.longDuration(
                        Duration(seconds: stats.durationSeconds),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceMuted,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${stats.sets}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    '${stats.sets == 1 ? 'set' : 'sets'} · ${stats.reps} reps',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          GlassProgressBar(
            value: stats.sets > 0 ? 1.0 : 0.0,
            height: 5,
          ),
        ],
      ),
    );
  }
}

/// The grid of summary statistics.
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats, required this.unit});

  final SessionStats stats;
  final SessionWeightUnit unit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: cardWidth,
              child: GlassStatisticCard(
                title: 'Volume',
                value: stats.volume,
                unit: unit == SessionWeightUnit.kg ? 'kg' : 'lb',
                icon: Icons.scale_rounded,
                decimals: 0,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: GlassStatisticCard(
                title: 'Sets',
                value: stats.sets.toDouble(),
                unit: 'sets',
                icon: Icons.repeat_rounded,
                decimals: 0,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: GlassStatisticCard(
                title: 'Reps',
                value: stats.reps.toDouble(),
                unit: 'reps',
                icon: Icons.format_list_numbered_rounded,
                decimals: 0,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: GlassStatisticCard(
                title: 'Best lift',
                value: stats.bestWeight,
                unit: unit == SessionWeightUnit.kg ? 'kg' : 'lb',
                icon: Icons.star_rounded,
                decimals: 1,
              ),
            ),
            if (stats.averageRpe != null)
              SizedBox(
                width: cardWidth,
                child: GlassStatisticCard(
                  title: 'Avg RPE',
                  value: stats.averageRpe!,
                  icon: Icons.speed_rounded,
                  decimals: 1,
                ),
              ),
            if (stats.calories > 0)
              SizedBox(
                width: cardWidth,
                child: GlassStatisticCard(
                  title: 'Calories',
                  value: stats.calories.toDouble(),
                  unit: 'kcal',
                  icon: Icons.local_fire_department_rounded,
                  decimals: 0,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A single unlocked achievement.
class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final SessionAchievement achievement;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: GlassDecoration(
        color: colors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: GlassBorder(color: colors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _achievementIcon(achievement.iconName),
            size: AppIconSize.medium,
            color: colors.success,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  achievement.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceMuted,
                      ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded,
              size: AppIconSize.small, color: colors.success),
        ],
      ),
    );
  }

  IconData _achievementIcon(String name) {
    switch (name) {
      case 'flag':
        return Icons.flag_rounded;
      case 'repeat':
        return Icons.repeat_rounded;
      case 'numbers':
        return Icons.format_list_numbered_rounded;
      case 'scale':
        return Icons.scale_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'schedule':
        return Icons.schedule_rounded;
      case 'grid_view':
        return Icons.grid_view_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}
