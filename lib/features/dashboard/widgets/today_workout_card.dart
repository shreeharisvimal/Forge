// Today's workout card for the Forge dashboard.
//
// Renders the split day scheduled for today — a training plan, a rest day,
// or a friendly prompt to set up a split when none is active.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/forge_design.dart';
import '../../../core/router/app_route_paths.dart';
import '../providers/dashboard_providers.dart';

/// The hero card describing today's scheduled workout.
class TodayWorkoutCard extends ConsumerWidget {
  /// Creates the today's workout card.
  const TodayWorkoutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(todayWorkoutProvider);

    if (!data.hasSplit) {
      return _NoSplitCard(
        onCreateSplit: () => context.push(AppRoutePaths.splits),
      );
    }

    final today = data.today;
    if (today == null || today.day.isRestDay) {
      return _RestDayCard(
        dayName: today?.day.name,
        onPlan: () => context.push(AppRoutePaths.splits),
      );
    }

    return _TrainingDayCard(
      splitName: data.splitName,
      accent: data.splitColor,
      dayName: today.day.name,
      focus: today.day.focus,
      exercises: today.day.exercises,
      loggedToday: data.loggedToday,
      estimatedMinutes: data.estimatedMinutes,
      muscleGroups: data.muscleGroups,
      recoveryPercent: data.recoveryPercent,
      recordCount: data.recordCount,
      onStart: () => context.push(AppRoutePaths.session),
    );
  }
}

class _NoSplitCard extends StatelessWidget {
  const _NoSplitCard({required this.onCreateSplit});

  final VoidCallback onCreateSplit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: AppSpacing.lg.all,
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          const _AccentIcon(icon: Icons.fitness_center_rounded),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set up a split',
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  'Pick a weekly plan and Forge will tell you what to train each day.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.lg),
          GlassButton(
            label: 'Create',
            icon: Icons.add_rounded,
            variant: GlassButtonVariant.tonal,
            onPressed: onCreateSplit,
          ),
        ],
      ),
    );
  }
}

class _RestDayCard extends StatelessWidget {
  const _RestDayCard({required this.dayName, required this.onPlan});

  final String? dayName;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: AppSpacing.lg.all,
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          const _AccentIcon(icon: Icons.spa_rounded),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName == null ? 'Rest day' : '$dayName · rest day',
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  'Recovery is training too. Rest up for tomorrow.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.lg),
          GlassButton(
            label: 'Plan',
            icon: Icons.view_week_outlined,
            variant: GlassButtonVariant.tonal,
            onPressed: onPlan,
          ),
        ],
      ),
    );
  }
}

class _TrainingDayCard extends StatelessWidget {
  const _TrainingDayCard({
    required this.splitName,
    required this.accent,
    required this.dayName,
    required this.focus,
    required this.exercises,
    required this.loggedToday,
    required this.estimatedMinutes,
    required this.muscleGroups,
    required this.recoveryPercent,
    required this.recordCount,
    required this.onStart,
  });

  final String? splitName;
  final int accent;
  final String dayName;
  final String focus;
  final List<dynamic> exercises;
  final bool loggedToday;
  final int estimatedMinutes;
  final List<String> muscleGroups;
  final double? recoveryPercent;
  final int recordCount;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    final accentColor = Color(accent);

    final preview = [
      for (final exercise in exercises.take(3))
        exercise.exerciseName as String,
    ];
    final remaining = exercises.length - preview.length;

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: AppSpacing.lg.all,
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AccentIcon(icon: Icons.play_arrow_rounded, accent: accent),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (splitName != null) ...[
                      Text(
                        splitName!,
                        style: textTheme.labelLarge?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxs),
                    ],
                    Text(
                      dayName,
                      style: textTheme.headlineSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (loggedToday)
                Semantics(
                  label: 'Workout completed today',
                  child: _CompletedChip(color: colors.success),
                ),
            ],
          ),
          if (focus.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              focus,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ],
          SizedBox(height: AppSpacing.lg),
          _SessionStats(
            exercises: exercises.length,
            minutes: estimatedMinutes,
            recoveryPercent: recoveryPercent,
            accent: accentColor,
          ),
          if (muscleGroups.isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                for (final group in muscleGroups) ...[
                  _MuscleTag(label: group, accent: accentColor),
                  SizedBox(width: AppSpacing.xs),
                ],
              ],
            ),
          ],
          if (preview.isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            Text(
              remaining > 0
                  ? '${preview.join(' · ')}, and $remaining more'
                  : preview.join(' · '),
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ],
          if (recordCount > 0) ...[
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  size: AppIconSize.extraSmall,
                  color: colors.warning,
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    recordCount == 1
                        ? '1 exercise is ready for a personal record'
                        : '$recordCount exercises are ready for personal records',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: AppSpacing.lg),
          GlassButton(
            label: loggedToday ? 'Start another workout' : 'Start workout',
            icon: Icons.play_arrow_rounded,
            size: GlassButtonSize.large,
            expanded: true,
            entrance: GlassEntrance.slide,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

/// A compact row of workout stats: exercises, estimated time and recovery.
class _SessionStats extends StatelessWidget {
  const _SessionStats({
    required this.exercises,
    required this.minutes,
    required this.recoveryPercent,
    required this.accent,
  });

  final int exercises;
  final int minutes;
  final double? recoveryPercent;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    final recovery = recoveryPercent;
    final recoveryLabel = recovery == null
        ? '—'
        : '${(recovery * 100).round()}% recovered';
    final recoveryColor = recovery == null
        ? colors.onSurfaceMuted
        : recovery >= 0.75
            ? colors.success
            : recovery >= 0.4
                ? colors.warning
                : colors.danger;

    Widget stat(String value, String label, {Color? valueColor}) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                color: valueColor ?? colors.onSurface,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        stat('$exercises', exercises == 1 ? 'exercise' : 'exercises'),
        Container(
          width: 1,
          height: AppSpacing.xxl,
          color: colors.border,
        ),
        stat(minutes > 0 ? '$minutes' : '—', 'min est.'),
        Container(
          width: 1,
          height: AppSpacing.xxl,
          color: colors.border,
        ),
        stat(recoveryLabel, 'muscles', valueColor: recoveryColor),
      ],
    );
  }
}

/// A small pill tag for a targeted muscle bucket.
class _MuscleTag extends StatelessWidget {
  const _MuscleTag({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
      decoration: GlassDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        border: GlassBorder(color: accent.withValues(alpha: 0.3)),
        highlight: false,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _AccentIcon extends StatelessWidget {
  const _AccentIcon({required this.icon, this.accent});

  final IconData icon;
  final int? accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final accent = Color(this.accent ?? colors.primary.toARGB32());

    return GlassContainer(
      width: AppSpacing.huge,
      height: AppSpacing.huge,
      borderRadius: BorderRadius.circular(AppRadius.large),
      decoration: GlassDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Center(
        child: Icon(
          icon,
          size: AppIconSize.large,
          color: accent,
        ),
      ),
    );
  }
}

class _CompletedChip extends StatelessWidget {
  const _CompletedChip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: AppIconSize.small, color: color),
          SizedBox(width: AppSpacing.xxs),
          Text(
            'Done',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

GlassDecoration _cardDecoration(BuildContext context) {
  final colors = Theme.of(context).forgeColors;
  return GlassDecoration(
    color: colors.glass,
    borderRadius: BorderRadius.circular(AppRadius.medium),
    border: const GlassBorder(),
  );
}
