// Exercise picker sheet for the workout session.
//
// A searchable bottom sheet listing exercises from the library so the user
// can add one to the in-progress session. Pops the chosen [Exercise].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/forge_design.dart';
import '../../../../models/exercise.dart';
import '../../../../services/providers.dart';

/// Presents the picker and resolves with the chosen [Exercise], or null.
Future<Exercise?> showExercisePicker(
  BuildContext context, {
  Set<String>? excludedIds,
}) {
  return context.showGlassBottomSheet<Exercise>(
    initialChildSize: 0.9,
    maxChildSize: 0.95,
    builder: (_) => ExercisePickerSheet(excludedIds: excludedIds ?? const {}),
  );
}

/// The searchable exercise list shown inside the picker sheet.
class ExercisePickerSheet extends ConsumerStatefulWidget {
  /// Creates the picker sheet.
  const ExercisePickerSheet({super.key, this.excludedIds = const {}});

  /// Library ids already in the session (hidden from the list).
  final Set<String> excludedIds;

  @override
  ConsumerState<ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final query = _query.trim().toLowerCase();
    final filtered = ref.watch(exerciseRepositoryProvider).all().where((e) {
      if (widget.excludedIds.contains(e.id)) return false;
      if (query.isEmpty) return true;
      return e.name.toLowerCase().contains(query);
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add exercise',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: AppSpacing.md),
        GlassSearchBar(
          hintText: 'Search exercises...',
          onChanged: (value) => setState(() => _query = value),
        ),
        SizedBox(height: AppSpacing.md),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Center(
              child: Text(
                'No exercises match',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
              ),
            ),
          )
        else
          for (final exercise in filtered) ...[
            GlassListTile(
              title: exercise.name,
              subtitle: exercise.muscleGroup,
              leading: Icon(
                Icons.fitness_center_rounded,
                size: AppIconSize.small,
                color: colors.primary,
              ),
              onTap: () => Navigator.of(context).pop(exercise),
            ),
            SizedBox(height: AppSpacing.xs),
          ],
      ],
    );
  }
}
