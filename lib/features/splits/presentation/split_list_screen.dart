// Split list screen for the Forge application.
//
// The management hub for weekly training splits: cards for each split with
// the active plan highlighted, quick actions (activate, edit, duplicate,
// delete) and a FAB to create a new split.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../../../core/dialogs/forge_dialogs.dart';
import '../../../models/workout_split.dart';
import '../../../services/providers.dart';
import '../providers/split_providers.dart';
import '../split_options.dart';
import 'split_editor_screen.dart';

/// Lists the user's training splits.
class SplitListScreen extends ConsumerWidget {
  /// Creates the split list screen.
  const SplitListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splits = ref.watch(workoutSplitsProvider);
    final activeId = ref.watch(activeSplitProvider)?.id;

    return Scaffold(
      body: Column(
        children: [
          GlassAppBar(title: 'Training Splits'),
          Expanded(
            child: splits.isEmpty
                ? _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: splits.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final split = splits[index];
                      return SplitCard(
                        split: split,
                        isActive: split.id == activeId,
                        onTap: () => _openEditor(context, ref, split),
                        onActivate: () => ref
                            .read(workoutSplitRepositoryProvider)
                            .activate(split.id),
                        onEdit: () => _openEditor(context, ref, split),
                        onDuplicate: () => _duplicate(context, ref, split),
                        onDelete: () => _delete(context, ref, split),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: GlassFAB(
        icon: Icons.add,
        label: 'New Split',
        onPressed: () => _openEditor(context, ref, null),
      ),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, WorkoutSplit? split) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SplitEditorScreen(split: split)),
    );
  }

  Future<void> _duplicate(
    BuildContext context,
    WidgetRef ref,
    WorkoutSplit split,
  ) async {
    final repository = ref.read(workoutSplitRepositoryProvider);
    final copy = split.copyWith(
      name: '${split.name} Copy',
      isActive: false,
      days: [
        for (final day in split.days)
          day.copyWith(
            exercises: [
              for (final exercise in day.exercises) exercise.copyWith(),
            ],
          ),
      ],
    );
    await repository.save(copy);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    WorkoutSplit split,
  ) async {
    final confirmed = await showForgeDeleteDialog(
      context,
      title: 'Delete split?',
      message: '"${split.name}" and its days will be permanently removed.',
    );
    if (confirmed == true && context.mounted) {
      await ref.read(workoutSplitRepositoryProvider).delete(split.id);
    }
  }
}

/// A single split card.
class SplitCard extends StatelessWidget {
  /// Creates a split card.
  const SplitCard({
    super.key,
    required this.split,
    required this.isActive,
    required this.onTap,
    required this.onActivate,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final WorkoutSplit split;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onActivate;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = Color(split.color);
    final colors = Theme.of(context).forgeColors;
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      child: Row(
        children: [
          GlassContainer(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(AppRadius.large),
            decoration: GlassDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: GlassBorder(color: accent.withValues(alpha: 0.4)),
            ),
            child: Icon(
              splitIcon(split.iconCodePoint),
              color: accent,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        split.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colors.onSurface,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: AppSpacing.sm),
                      GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                        decoration: GlassDecoration(
                          color: accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${split.trainingDayCount} training days · '
                  '${split.exerciseCount} exercises',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceMuted,
                      ),
                ),
              ],
            ),
          ),
          GlassIconButton(
            icon: Icons.more_vert,
            color: colors.onSurfaceTertiary,
            semanticLabel: 'Split actions',
            onPressed: () => _showActions(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final colors = Theme.of(context).forgeColors;
    final result = await GlassBottomSheet.show<String>(
      context,
      maxChildSize: 0.5,
      showDragHandle: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isActive) ...[
            GlassListTile(
              title: 'Set as active',
              leading:
                  Icon(Icons.play_circle_outline, color: colors.primary),
              onTap: () => Navigator.of(context).pop('activate'),
            ),
            SizedBox(height: AppSpacing.xs),
          ],
          GlassListTile(
            title: 'Edit',
            leading: Icon(Icons.edit_outlined, color: colors.primary),
            onTap: () => Navigator.of(context).pop('edit'),
          ),
          SizedBox(height: AppSpacing.xs),
          GlassListTile(
            title: 'Duplicate',
            leading: Icon(Icons.copy_all_outlined, color: colors.onSurfaceMuted),
            onTap: () => Navigator.of(context).pop('duplicate'),
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
    switch (result) {
      case 'activate':
        onActivate();
      case 'edit':
        onEdit();
      case 'duplicate':
        onDuplicate();
      case 'delete':
        onDelete();
    }
  }
}

/// Empty state when no splits exist yet.
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassEmptyState(
      icon: Icons.fitness_center,
      title: 'No training splits yet',
      message: 'Create a weekly split to organize your workouts.',
    );
  }
}
