// Progress achievements section for the Forge application.
//
// Every milestone evaluated against the lifetime history, shown as a grid
// of progress tiles so locked, in-progress and unlocked states read at a
// glance.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/forge_design.dart';
import '../domain/achievements.dart';
import '../providers/progress_providers.dart';
import 'progress_section_header.dart';

/// The achievements grid for the whole training history.
class ProgressAchievementsSection extends ConsumerWidget {
  /// Creates the achievements section.
  const ProgressAchievementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final states = ref.watch(progressAchievementsProvider);
    final unlocked = states
        .where((state) => state.status == AchievementStatus.unlocked)
        .length;
    final columns = Responsive.columns(
      context,
      compact: 2,
      medium: 3,
      expanded: 4,
    );
    final spacing = AppSpacing.md;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProgressSectionHeader(
          title: 'Achievements',
          subtitle: '$unlocked unlocked',
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
                for (final state in states)
                  SizedBox(
                    width: itemWidth,
                    child: _AchievementTile(state: state),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// A single achievement tile.
class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.state});

  final AchievementState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final unlocked = state.status == AchievementStatus.unlocked;
    final inProgress = state.status == AchievementStatus.inProgress;
    final accent = unlocked
        ? colors.success
        : inProgress
            ? colors.primary
            : colors.onSurfaceMuted;
    final progressColor = unlocked
        ? colors.success
        : inProgress
            ? colors.primary
            : colors.outline;

    return Semantics(
      label:
          '${state.achievement.title}, ${unlocked ? 'unlocked' : state.status.name}',
      child: GlassContainer(
        width: double.infinity,
        padding: AppSpacing.md.all,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        decoration: GlassDecoration(
          color: colors.glass,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: GlassBorder(
            color: unlocked
                ? colors.success.withValues(alpha: 0.5)
                : ForgeColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _achievementIcon(state.achievement.iconName),
                  size: AppIconSize.medium,
                  color: accent,
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    state.achievement.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            GlassProgressBar(
              value: state.progress.clamp(0.0, 1.0),
              height: 4,
              color: progressColor,
            ),
            if (unlocked || inProgress) ...[
              SizedBox(height: AppSpacing.xs),
              Text(
                unlocked
                    ? 'Unlocked'
                    : '${(state.progress * 100).round()}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: unlocked ? colors.success : colors.onSurfaceMuted,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Resolves the icon name stored on an [Achievement] to an [IconData].
IconData _achievementIcon(String iconName) => switch (iconName) {
      'fitness' => Icons.fitness_center_rounded,
      'local_fire_department' => Icons.local_fire_department_rounded,
      'whatshot' => Icons.whatshot_rounded,
      'military_tech' => Icons.military_tech_rounded,
      'emoji_events' => Icons.emoji_events_rounded,
      'layers' => Icons.layers_rounded,
      'local_shipping' => Icons.local_shipping_rounded,
      'iron' => Icons.iron_rounded,
      'format_list_numbered' => Icons.format_list_numbered_rounded,
      'flag' => Icons.flag_rounded,
      'bolt' => Icons.bolt_rounded,
      'trending_up' => Icons.trending_up_rounded,
      'accessibility_new' => Icons.accessibility_new_rounded,
      'monitor_weight' => Icons.monitor_weight_rounded,
      _ => Icons.emoji_events_rounded,
    };
