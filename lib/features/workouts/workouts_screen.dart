// Workouts feature screen for the Forge application.
//
// The training hub tab: today's scheduled workout, the next upcoming session,
// quick shortcuts to the exercise library, splits and templates, and a recent
// history list. The hero cards are shared with the dashboard so the plan is
// presented identically everywhere.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/forge_design.dart';
import '../../core/router/app_route_paths.dart';
import '../../models/workout_session.dart';
import '../../models/workout_template.dart';
import '../dashboard/widgets/dashboard_formatters.dart';
import '../dashboard/widgets/today_workout_card.dart';
import '../dashboard/widgets/upcoming_workout_card.dart';
import '../search/global_search_sheet.dart';
import '../workout_session/domain/session_models.dart';
import '../workout_session/providers/session_providers.dart';
import 'providers/workouts_providers.dart';

/// Workouts screen — the training hub tab.
class WorkoutsScreen extends ConsumerWidget {
  /// Creates the workouts screen.
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeSessionProvider).value;
    final recent = ref.watch(recentSessionsProvider);

    return Scaffold(
      body: Column(
        children: [
          GlassAppBar(
            title: 'Workouts',
            actions: [
              GlassIconButton(
                icon: Icons.search,
                tooltip: 'Search everything',
                semanticLabel: 'Search everything',
                onPressed: () => showGlobalSearchSheet(context),
              ),
              GlassIconButton(
                icon: Icons.view_week_outlined,
                tooltip: 'Training splits',
                semanticLabel: 'Training splits',
                onPressed: () => context.push(AppRoutePaths.splits),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.huge,
              ),
              children: [
                if (activeSession != null) ...[
                  _ResumeBanner(
                    sessionName: activeSession.name,
                    stage: activeSession.stage,
                    onTap: () => context.push(AppRoutePaths.session),
                  ),
                  SizedBox(height: AppSpacing.lg),
                ],
                const TodayWorkoutCard(),
                const SizedBox(height: AppSpacing.lg),
                const UpcomingWorkoutCard(),
                const SizedBox(height: AppSpacing.lg),
                const _HubActions(),
                const SizedBox(height: AppSpacing.lg),
                _RecentWorkoutsCard(sessions: recent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner shown while a workout session is in progress.
class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({
    required this.sessionName,
    required this.stage,
    required this.onTap,
  });

  final String sessionName;
  final SessionStage stage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    final resumed = stage != SessionStage.preparation;

    return GlassPressable(
      onTap: onTap,
      semanticLabel: resumed ? 'Resume workout' : 'Open workout',
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: AppSpacing.lg.all,
        decoration: GlassDecoration(
          color: colors.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: GlassBorder(color: colors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            GlassContainer(
              width: AppSpacing.huge,
              height: AppSpacing.huge,
              borderRadius: BorderRadius.circular(AppRadius.large),
              decoration: GlassDecoration(
                color: colors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              child: Center(
                child: Icon(
                  resumed
                      ? Icons.timer_rounded
                      : Icons.edit_note_rounded,
                  size: AppIconSize.large,
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
                    resumed ? 'Workout in progress' : 'Workout prepared',
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    sessionName.isEmpty ? 'Session' : sessionName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            GlassButton(
              label: resumed ? 'Resume' : 'Continue',
              icon: Icons.play_arrow_rounded,
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shortcuts to the app's training destinations.
class _HubActions extends ConsumerWidget {
  const _HubActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(workoutTemplatesProvider);

    return GlassChartContainer(
      title: 'Training',
      child: Row(
        children: [
          Expanded(
            child: _HubActionTile(
              label: 'Exercise Library',
              icon: Icons.fitness_center_rounded,
              onTap: () => context.push(AppRoutePaths.exerciseLibrary),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _HubActionTile(
              label: 'Splits',
              icon: Icons.view_week_outlined,
              onTap: () => context.push(AppRoutePaths.splits),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _HubActionTile(
              label: 'Templates',
              icon: Icons.file_copy_outlined,
              badge: templates.isEmpty ? null : '${templates.length}',
              onTap: () => _showTemplatesSheet(context, templates),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _HubActionTile(
              label: 'History',
              icon: Icons.history_rounded,
              onTap: () => context.go(AppRoutePaths.calendar),
            ),
          ),
        ],
      ),
    );
  }

  void _showTemplatesSheet(BuildContext context, List<WorkoutTemplate> templates) {
    GlassBottomSheet.show(
      context,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context) => _TemplatesSheet(templates: templates),
    );
  }
}

/// A single tappable hub shortcut.
class _HubActionTile extends StatelessWidget {
  const _HubActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return GlassPressable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: GlassContainer(
        width: double.infinity,
        padding: AppSpacing.md.all,
        borderRadius: BorderRadius.circular(AppRadius.small),
        decoration: GlassDecoration(
          color: colors.glassStrong,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: AppIconSize.medium, color: colors.primary),
                if (badge != null)
                  Positioned(
                    right: -AppSpacing.sm,
                    top: -AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxs,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius:
                            BorderRadius.circular(AppRadius.extraLarge),
                      ),
                      child: Text(
                        badge!,
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(color: colors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only list of the user's saved workout templates.
class _TemplatesSheet extends StatelessWidget {
  const _TemplatesSheet({required this.templates});

  final List<WorkoutTemplate> templates;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            'Templates',
            style: textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (templates.isEmpty)
          Expanded(
            child: GlassEmptyState(
              icon: Icons.file_copy_outlined,
              title: 'No templates yet',
              message: 'Templates will appear here so you can start a '
                  'workout with the same exercises every time.',
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              itemCount: templates.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final template = templates[index];
                return GlassCard(
                  margin: EdgeInsets.zero,
                  padding: AppSpacing.md.all,
                  decoration: GlassDecoration(
                    color: colors.glass,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: const GlassBorder(),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.file_copy_outlined,
                        size: AppIconSize.medium,
                        color: colors.primary,
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xxs),
                            Text(
                              _subtitle(template),
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _subtitle(WorkoutTemplate template) {
    final count = template.exerciseIds.length;
    if (count == 0) return 'No exercises';
    return count == 1 ? '1 exercise' : '$count exercises';
  }
}

/// Recent performed sessions list.
class _RecentWorkoutsCard extends StatelessWidget {
  const _RecentWorkoutsCard({required this.sessions});

  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    final shown = sessions.take(5).toList();

    return GlassChartContainer(
      title: 'Recent workouts',
      child: shown.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                'No workouts logged yet. Finish your first session and it '
                'will show up here.',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  _RecentRow(session: shown[i]),
                  if (i != shown.length - 1) GlassDivider(),
                ],
              ],
            ),
    );
  }
}

/// A single recent session row.
class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    final name = session.name;
    final exercises = session.exercises.length;
    final minutes = session.durationMinutes;
    final date = session.date;

    final parts = <String>[
      '$exercises ${exercises == 1 ? 'exercise' : 'exercises'}',
      if (minutes > 0) '$minutes min',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          GlassContainer(
            width: AppSpacing.xl,
            height: AppSpacing.xl,
            borderRadius: BorderRadius.circular(AppRadius.small),
            decoration: GlassDecoration(
              color: colors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Center(
              child: Icon(
                Icons.fitness_center_rounded,
                size: AppIconSize.small,
                color: colors.primary,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Workout' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  parts.join(' · '),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            relativeDay(date, DateTime.now()),
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
