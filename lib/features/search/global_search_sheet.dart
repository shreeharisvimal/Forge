// Global search sheet for the Forge application.
//
// A full-height glass bottom sheet that searches exercises, splits,
// templates and performed sessions from one field. Opened from the workouts
// hub; results navigate to the matching destination.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/forge_design.dart';
import '../../core/router/app_route_paths.dart';
import '../../models/exercise.dart';
import '../../models/workout_session.dart';
import '../../models/workout_split.dart';
import '../../models/workout_template.dart';
import 'global_search_providers.dart';

/// Opens the global search sheet.
Future<void> showGlobalSearchSheet(BuildContext context) {
  return GlassBottomSheet.show(
    context,
    initialChildSize: 0.85,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    builder: (context) => const GlobalSearchSheet(),
  );
}

/// The search sheet body.
class GlobalSearchSheet extends ConsumerStatefulWidget {
  /// Creates the search sheet.
  const GlobalSearchSheet({super.key});

  @override
  ConsumerState<GlobalSearchSheet> createState() => _GlobalSearchSheetState();
}

class _GlobalSearchSheetState extends ConsumerState<GlobalSearchSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(globalSearchQueryProvider);
    final results = ref.watch(globalSearchResultsProvider);

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
          child: GlassSearchBar(
            controller: _controller,
            hintText: 'Search exercises, splits, history…',
            autofocus: true,
            onChanged: (value) =>
                ref.read(globalSearchQueryProvider.notifier).state = value,
          ),
        ),
        Expanded(
          child: query.trim().isEmpty
              ? const _SearchPrompt()
              : results.isEmpty
                  ? _NoResults(query: query.trim())
                  : _ResultsList(results: results),
        ),
      ],
    );
  }
}

/// Prompt shown before any query.
class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt();

  @override
  Widget build(BuildContext context) {
    return GlassEmptyState(
      icon: Icons.search,
      title: 'Search everything',
      message: 'Find an exercise, a training split, a template or a past '
          'workout session.',
    );
  }
}

/// Empty-result state.
class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return GlassEmptyState(
      icon: Icons.search_off,
      title: 'No results',
      message: 'Nothing matches "$query". Try a different spelling.',
    );
  }
}

/// The grouped result list.
class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.results});

  final GlobalSearchResults results;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.huge,
      ),
      children: [
        if (results.exercises.isNotEmpty) ...[
          _SectionHeader(label: 'Exercises'),
          for (final result in results.exercises)
            _ExerciseRow(exercise: result.item),
        ],
        if (results.splits.isNotEmpty) ...[
          _SectionHeader(label: 'Splits'),
          for (final result in results.splits)
            _SplitRow(split: result.item),
        ],
        if (results.templates.isNotEmpty) ...[
          _SectionHeader(label: 'Templates'),
          for (final result in results.templates)
            _TemplateRow(template: result.item),
        ],
        if (results.sessions.isNotEmpty) ...[
          _SectionHeader(label: 'History'),
          for (final result in results.sessions)
            _SessionRow(session: result.item),
        ],
      ],
    );
  }
}

/// A section title inside the results list.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// A tappable search result row.
class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    final accent = this.accent ?? colors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassPressable(
        onTap: onTap,
        semanticLabel: title,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: GlassCard(
          margin: EdgeInsets.zero,
          padding: AppSpacing.md.all,
          decoration: GlassDecoration(
            color: colors.glass,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: const GlassBorder(),
          ),
          child: Row(
            children: [
              GlassContainer(
                width: AppSpacing.xl,
                height: AppSpacing.xl,
                borderRadius: BorderRadius.circular(AppRadius.small),
                decoration: GlassDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Center(
                  child: Icon(icon, size: AppIconSize.small, color: accent),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return _ResultRow(
      icon: Icons.fitness_center_rounded,
      title: exercise.name,
      subtitle: [exercise.muscleGroup, exercise.equipment]
          .where((part) => part.isNotEmpty)
          .join(' · '),
      onTap: () {
        context.pushNamed(
          AppRouteNames.exerciseDetail,
          pathParameters: {'id': exercise.id},
        );
      },
    );
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({required this.split});

  final WorkoutSplit split;

  @override
  Widget build(BuildContext context) {
    return _ResultRow(
      icon: Icons.view_week_outlined,
      title: split.name,
      subtitle: split.days.isEmpty
          ? 'No days'
          : split.trainingDayCount == 1
              ? '1 training day'
              : '${split.trainingDayCount} training days',
      accent: Color(split.color),
      onTap: () => context.push(AppRoutePaths.splits),
    );
  }
}

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({required this.template});

  final WorkoutTemplate template;

  @override
  Widget build(BuildContext context) {
    final count = template.exerciseIds.length;
    return _ResultRow(
      icon: Icons.file_copy_outlined,
      title: template.name,
      subtitle: count == 0 ? 'No exercises' : '$count exercises',
      onTap: () => context.push(AppRoutePaths.exerciseLibrary),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final exercises = session.exercises.length;
    final parts = <String>[
      '$exercises ${exercises == 1 ? 'exercise' : 'exercises'}',
      if (session.durationMinutes > 0) '${session.durationMinutes} min',
    ];
    return _ResultRow(
      icon: Icons.history_rounded,
      title: session.name.isEmpty ? 'Workout' : session.name,
      subtitle: parts.join(' · '),
      onTap: () => context.go(AppRoutePaths.calendar),
    );
  }
}
