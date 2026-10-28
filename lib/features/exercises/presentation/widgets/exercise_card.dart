// Reusable widgets for the exercise library feature.
//
// The [ExerciseCard] is the primary list item: avatar, name (with optional
// search match highlighting), muscle/equipment metadata, tag chips, a
// favorite toggle and an overflow menu for edit/archive/delete.
library;

import 'package:flutter/material.dart';

import '../../../../core/design/forge_design.dart';
import '../../../../models/exercise.dart';



/// An icon for common equipment types.
IconData equipmentIcon(String equipment) {
  switch (equipment) {
    case 'Barbell':
      return Icons.sports_gymnastics;
    case 'Dumbbell':
      return Icons.fitness_center;
    case 'Kettlebell':
      return Icons.fitness_center;
    case 'Cable':
      return Icons.swap_vert;
    case 'Machine':
      return Icons.precision_manufacturing;
    case 'Bodyweight':
      return Icons.accessibility_new;
    case 'Cardio':
      return Icons.directions_run;
    case 'Foam Roller':
      return Icons.spa;
    default:
      return Icons.sports_gymnastics;
  }
}

/// A single exercise row in the library.
class ExerciseCard extends StatelessWidget {
  /// Creates an exercise card.
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
    this.query = '',
  });

  /// The exercise to display.
  final Exercise exercise;

  /// Called when the card is tapped.
  final VoidCallback onTap;

  /// Called when the favorite star is toggled.
  final VoidCallback onToggleFavorite;

  /// Called when "Edit" is chosen.
  final VoidCallback onEdit;

  /// Called when "Archive"/"Restore" is chosen.
  final VoidCallback onArchive;

  /// Called when "Delete" is chosen.
  final VoidCallback onDelete;

  /// Active search text (used to highlight name matches).
  final String query;

  @override
  Widget build(BuildContext context) {
    return GlassExerciseTile(
      title: exercise.name,
      subtitle: '${exercise.muscleGroup} · ${exercise.equipment}',
      equipmentIcon: equipmentIcon(exercise.equipment),
      tags: exercise.tags,
      isFavorite: exercise.favorite,
      onFavoriteToggle: onToggleFavorite,
      query: query,
      onTap: onTap,
      trailing: _OverflowMenu(
        archived: exercise.archived,
        onEdit: onEdit,
        onArchive: onArchive,
        onDelete: onDelete,
      ),
    );
  }
}




/// Edit / archive / delete actions.
class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({
    required this.archived,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  /// Whether the parent exercise is currently archived.
  final bool archived;

  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return GlassIconButton(
      icon: Icons.more_vert,
      color: colors.onSurfaceTertiary,
      semanticLabel: 'Actions',
      onPressed: () => _showActions(context),
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
          GlassListTile(
            title: 'Edit',
            leading: Icon(Icons.edit_outlined, color: colors.primary),
            onTap: () => Navigator.of(context).pop('edit'),
          ),
          SizedBox(height: AppSpacing.xs),
          GlassListTile(
            title: archived ? 'Restore' : 'Archive',
            leading: Icon(Icons.archive_outlined, color: colors.onSurfaceMuted),
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
    switch (result) {
      case 'edit':
        onEdit();
      case 'archive':
        onArchive();
      case 'delete':
        onDelete();
    }
  }
}
