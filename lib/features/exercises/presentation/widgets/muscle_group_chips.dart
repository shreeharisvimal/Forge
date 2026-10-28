// Muscle group filter chips for the exercise library.
//
// A horizontally scrolling row of ChoiceChips - one per muscle group that
// exists in the library - with an "All" option that clears the filter.
library;

import 'package:flutter/material.dart';

import '../../../../core/design/forge_design.dart';

/// Horizontal scrollable muscle group filter.
class MuscleGroupChips extends StatelessWidget {
  /// Creates the chip row.
  const MuscleGroupChips({
    super.key,
    required this.groups,
    required this.selected,
    required this.onSelected,
  });

  /// The muscle groups to offer, in display order.
  final List<String> groups;

  /// The currently selected group, or null for "All".
  final String? selected;

  /// Called when a chip is chosen (null clears the filter).
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: groups.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return GlassChip(
              label: 'All',
              selected: selected == null,
              onTap: () => onSelected(null),
            );
          }
          final group = groups[index - 1];
          return GlassChip(
            label: group,
            selected: selected == group,
            onTap: () => onSelected(group),
          );
        },
      ),
    );
  }
}
