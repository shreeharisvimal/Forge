// Exercise detail screen.
//
// Shows the full profile for one exercise: classification chips, default
// workout settings as stat tiles, tags, coaching content and provenance.
// The app bar hosts favorite / edit / archive / delete actions, with deletion
// guarded by the reference checker.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../../../core/dialogs/forge_dialogs.dart';
import '../../../models/exercise.dart';
import '../../../services/providers.dart';
import '../../../services/repositories/exercise_repository.dart';
import '../data/exercise_reference_checker.dart';
import '../providers/exercise_library_providers.dart';
import 'exercise_edit_screen.dart';
import 'widgets/exercise_card.dart';
import 'widgets/stat_tile.dart';

/// Shows a single exercise's full profile.
class ExerciseDetailScreen extends ConsumerWidget {
  /// Creates the detail screen.
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  /// The id of the exercise to show.
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(exerciseRepositoryProvider);
    final exercise = repository.byId(exerciseId);

    if (exercise == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              'Exercise not found',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Theme.of(context).forgeColors.onSurfaceMuted),
            ),
          ),
        ),
      );
    }

    final checker = ref.read(exerciseReferenceCheckerProvider);
    final colors = Theme.of(context).forgeColors;

    return Scaffold(
      body: Column(
        children: [
          GlassAppBar(
            title: exercise.name,
            actions: [
              GlassIconButton(
                icon: exercise.favorite ? Icons.star : Icons.star_border,
                tooltip: exercise.favorite ? 'Unfavorite' : 'Favorite',
                semanticLabel: exercise.favorite ? 'Unfavorite' : 'Favorite',
                color: exercise.favorite ? colors.warning : colors.onSurfaceTertiary,
                onPressed: () async {
                  await repository
                      .save(exercise.copyWith(favorite: !exercise.favorite));
                },
              ),
              GlassIconButton(
                icon: Icons.more_vert,
                tooltip: 'Actions',
                semanticLabel: 'Actions',
                onPressed: () => _showActions(context, ref, exercise, checker),
              ),
            ],
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _Header(exercise: exercise),
            const SizedBox(height: AppSpacing.lg),
            _SettingsGrid(exercise: exercise),
            if (exercise.tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                title: 'Tags',
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final tag in exercise.tags)
                      GlassChip(label: tag),
                  ],
                ),
              ),
            ],
            if (exercise.instructions.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                title: 'Instructions',
                child: Text(
                  exercise.instructions,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        height: 1.5,
                      ),
                ),
              ),
            ],
            if (exercise.secondaryMuscles.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                title: 'Secondary muscles',
                child: Text(
                  exercise.secondaryMuscles.join(', '),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                ),
              ),
            ],
            if (exercise.notes.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                title: 'Notes',
                child: Text(
                  exercise.notes,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceMuted,
                        height: 1.5,
                      ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _Provenance(exercise: exercise),
            const SizedBox(height: AppSpacing.xl),
          ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    Exercise exercise,
    ExerciseReferenceChecker checker,
  ) async {
    final colors = Theme.of(context).forgeColors;
    final result = await GlassBottomSheet.show<String>(
      context,
      maxChildSize: 0.5,
      showDragHandle: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassListTile(
            title: 'Edit',
            leading: Icon(Icons.edit_outlined, color: colors.primary),
            onTap: () => Navigator.of(context).pop('edit'),
          ),
          SizedBox(height: AppSpacing.xs),
          GlassListTile(
            title: exercise.archived ? 'Restore' : 'Archive',
            leading:
                Icon(Icons.archive_outlined, color: colors.onSurfaceMuted),
            onTap: () => Navigator.of(context).pop('archive'),
          ),
          SizedBox(height: AppSpacing.xs),
          GlassListTile(
            title: 'Delete',
            leading: Icon(Icons.delete_outline, color: colors.danger),
            trailing: Icon(Icons.chevron_right_rounded, color: colors.danger),
            onTap: () => Navigator.of(context).pop('delete'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (result != null) {
      await _handleMenu(context, ref, result, exercise, checker);
    }
  }

  Future<void> _handleMenu(
    BuildContext context,
    WidgetRef ref,
    String value,
    Exercise exercise,
    ExerciseReferenceChecker checker,
  ) async {
    final repository = ref.read(exerciseRepositoryProvider);
    switch (value) {
      case 'edit':
        final edited = await Navigator.of(context).push<Exercise>(
          MaterialPageRoute(
            builder: (_) => ExerciseEditScreen(exercise: exercise),
          ),
        );
        if (edited != null && context.mounted) {
          // Stay on detail; the watched repository reflects the new values.
        }
      case 'archive':
        await repository
            .save(exercise.copyWith(archived: !exercise.archived));
        if (context.mounted) Navigator.of(context).pop();
      case 'delete':
        await _confirmDelete(context, repository, checker, exercise);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ExerciseRepository repository,
    ExerciseReferenceChecker checker,
    Exercise exercise,
  ) async {
    final references = checker.referencesFor(exercise.id);

    if (references.isReferenced) {
      await _showReferencedDialog(context, exercise, references);
      return;
    }

    final confirmed = await showForgeDeleteDialog(
      context,
      title: 'Delete exercise?',
      message:
          '"${exercise.name}" will be permanently removed from your library.',
    );

    if (confirmed == true && context.mounted) {
      await repository.delete(exercise.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _showReferencedDialog(
    BuildContext context,
    Exercise exercise,
    ExerciseReferenceInfo references,
  ) async {
    final parts = <String>[
      if (references.workouts > 0) '${references.workouts} workouts',
      if (references.templates > 0) '${references.templates} templates',
      if (references.sessions > 0) '${references.sessions} sessions',
      if (references.records > 0) '${references.records} records',
    ];
    await showForgeInfoDialog(
      context,
      title: 'Exercise is in use',
      message:
          '"${exercise.name}" is used in ${parts.join(', ')}. Archive it '
          'instead to hide it while keeping your history intact.',
    );
  }
}

/// Avatar + name + classification chips header.
class _Header extends StatelessWidget {
  const _Header({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Row(
      children: [
        GlassContainer(
          width: 64,
          height: 64,
          borderRadius: BorderRadius.circular(AppRadius.large),
          decoration: GlassDecoration(
            color: colors.primary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: GlassBorder(
              color: colors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(
            equipmentIcon(exercise.equipment),
            color: colors.primary,
            size: 32,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.onSurface,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  _InfoChip(label: exercise.muscleGroup),
                  _InfoChip(label: exercise.equipment),
                  if (exercise.isCompound) const _InfoChip(label: 'Compound'),
                  if (exercise.archived) const _InfoChip(label: 'Archived'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small outlined classification chip.
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      borderRadius: BorderRadius.circular(AppRadius.small),
      decoration: GlassDecoration(
        color: colors.glassStrong,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: const GlassBorder(color: ForgeColors.border, width: AppBorderWidth.thin),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceMuted,
            ),
      ),
    );
  }
}

/// Default workout settings as stat tiles.
class _SettingsGrid extends StatelessWidget {
  const _SettingsGrid({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        StatTile(label: 'Sets', value: '${exercise.defaultSets}'),
        StatTile(label: 'Reps', value: '${exercise.defaultReps}'),
        StatTile(
          label: 'Rest',
          value: '${exercise.defaultRestSeconds}s',
        ),
        StatTile(
          label: 'RPE',
          value: exercise.defaultRpe?.toStringAsFixed(1) ?? '—',
        ),
        StatTile(
          label: 'Tempo',
          value: exercise.tempo.trim().isEmpty ? '—' : exercise.tempo,
        ),
        StatTile(
          label: 'Used',
          value: '${exercise.usageCount}×',
        ),
      ],
    );
  }
}

/// A titled content card.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: child,
        ),
      ],
    );
  }
}

/// Source + created/updated footer.
class _Provenance extends StatelessWidget {
  const _Provenance({required this.exercise});

  final Exercise exercise;

  String _format(DateTime date) {
    final local = date.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final source = exercise.source == ExerciseSource.seed
        ? 'Bundled exercise'
        : 'Created by you';
    return Text(
      '$source · added ${_format(exercise.createdAt)}',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).forgeColors.onSurfaceMuted,
          ),
    );
  }
}
