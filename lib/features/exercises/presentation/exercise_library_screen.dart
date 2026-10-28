// Exercise library screen.
//
// The heart of the workouts tab: debounced search with match highlighting,
// muscle group filter chips, equipment/compound/favorites filters, a sort
// menu, an alphabet index rail, and grouped sections (favorites, recent,
// then A-Z). Long-press menu actions and delete guards are shared with the
// detail screen.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../../../core/dialogs/forge_dialogs.dart';
import '../../../core/overlays/forge_overlay_extensions.dart';
import '../../../models/exercise.dart';
import '../../../services/providers.dart';
import '../../../services/repositories/exercise_repository.dart';
import '../data/exercise_reference_checker.dart';
import '../providers/exercise_library_providers.dart';
import '../../splits/presentation/split_list_screen.dart';
import 'exercise_detail_screen.dart';
import 'exercise_edit_screen.dart';
import 'widgets/exercise_card.dart';
import 'widgets/muscle_group_chips.dart';

/// The exercise library landing screen.
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  /// Creates the library screen.
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        ref.read(exerciseLibraryFilterProvider.notifier).setQuery(value);
      }
    });
  }

  Future<void> _pickSort(
    BuildContext context,
    ExerciseSort current,
  ) async {
    final picked = await showForgeSelectionDialog<ExerciseSort>(
      context,
      title: 'Sort by',
      selected: current,
      options: const [
        ForgeSelectionOption(
          label: 'Alphabetical',
          value: ExerciseSort.alphabetical,
          icon: Icons.sort_by_alpha,
        ),
        ForgeSelectionOption(
          label: 'Recently used',
          value: ExerciseSort.recentlyUsed,
          icon: Icons.history,
        ),
        ForgeSelectionOption(
          label: 'Most used',
          value: ExerciseSort.mostUsed,
          icon: Icons.repeat,
        ),
        ForgeSelectionOption(
          label: 'Newest',
          value: ExerciseSort.newest,
          icon: Icons.fiber_new,
        ),
        ForgeSelectionOption(
          label: 'Oldest',
          value: ExerciseSort.oldest,
          icon: Icons.schedule,
        ),
      ],
    );
    if (picked != null) {
      ref.read(exerciseLibraryFilterProvider.notifier).setSort(picked);
    }
  }

  void _toggleFavorite(Exercise exercise) async {
    final repository = ref.read(exerciseRepositoryProvider);
    await repository.save(exercise.copyWith(favorite: !exercise.favorite));
  }

  void _openDetail(Exercise exercise) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(exerciseId: exercise.id),
      ),
    );
  }

  void _openEdit([Exercise? exercise]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseEditScreen(exercise: exercise),
      ),
    );
  }

  Future<void> _archive(Exercise exercise) async {
    final repository = ref.read(exerciseRepositoryProvider);
    await repository.save(exercise.copyWith(archived: !exercise.archived));
    if (mounted) {
      context.showToast(
        exercise.archived
            ? '"${exercise.name}" restored.'
            : '"${exercise.name}" archived.',
        actionLabel: 'Undo',
        action: () async {
          await repository.save(exercise.copyWith(archived: !exercise.archived));
        },
      );
    }
  }

  Future<void> _delete(Exercise exercise) async {
    final checker = ref.read(exerciseReferenceCheckerProvider);
    final references = checker.referencesFor(exercise.id);
    final repository = ref.read(exerciseRepositoryProvider);

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

    if (confirmed == true && mounted) {
      await repository.delete(exercise.id);
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

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(exerciseRepositoryProvider);
    final results = ref.watch(exerciseLibraryResultsProvider);
    final filter = ref.watch(exerciseLibraryFilterProvider);
    final filterNotifier = ref.read(exerciseLibraryFilterProvider.notifier);
    final groups = repository.muscleGroups();
    final favorites = repository.favorites();
    final hasArchived = repository
        .all()
        .any((exercise) => exercise.archived);

    return Scaffold(
      body: Column(
        children: [
          GlassAppBar(
            title: 'Exercise Library',
            actions: [
              GlassIconButton(
                icon: Icons.calendar_view_week,
                tooltip: 'Training splits',
                semanticLabel: 'Training splits',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SplitListScreen(),
                  ),
                ),
              ),
              GlassIconButton(
                icon: Icons.sort,
                tooltip: 'Sort',
                semanticLabel: 'Sort',
                onPressed: () => _pickSort(context, filter.sort),
              ),
              if (hasArchived)
                GlassIconButton(
                  icon: filter.showArchived
                      ? Icons.archive
                      : Icons.unarchive_outlined,
                  tooltip:
                      filter.showArchived ? 'Hide archived' : 'Show archived',
                  semanticLabel:
                      filter.showArchived ? 'Hide archived' : 'Show archived',
                  onPressed: filterNotifier.toggleShowArchived,
                ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: GlassSearchBar(
                    controller: _searchController,
                    hintText: 'Search exercises',
                    onChanged: _onSearchChanged,
                  ),
                ),
                MuscleGroupChips(
                  groups: groups,
                  selected: filter.muscleGroup,
                  onSelected: filterNotifier.setMuscleGroup,
                ),
                const SizedBox(height: AppSpacing.sm),
                _FilterBar(
                  filter: filter,
                  onEquipmentChanged: filterNotifier.setEquipment,
                  onCompoundChanged: filterNotifier.setCompound,
                  onToggleFavorites: filterNotifier.toggleFavoritesOnly,
                  onClear: filterNotifier.clearFilters,
                ),
                const SizedBox(height: AppSpacing.xs),
                Expanded(
                  child: results.isEmpty
                      ? _EmptyState(
                          hasActiveFilter: filter.isActive,
                          onClear: filterNotifier.clearFilters,
                        )
                      : _LibraryList(
                          exercises: results,
                          favorites: favorites,
                          groupedByLetter:
                              filter.sort == ExerciseSort.alphabetical,
                          showSections:
                              !filter.isActive &&
                              filter.sort == ExerciseSort.alphabetical,
                          query: filter.query,
                          onTap: _openDetail,
                          onEdit: _openEdit,
                          onToggleFavorite: _toggleFavorite,
                          onArchive: _archive,
                          onDelete: _delete,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: GlassFAB(
        icon: Icons.add,
        label: 'New Exercise',
        onPressed: () => _openEdit(),
      ),
    );
  }
}

/// Equipment / compound / favorites filter row.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.onEquipmentChanged,
    required this.onCompoundChanged,
    required this.onToggleFavorites,
    required this.onClear,
  });

  final ExerciseLibraryFilter filter;
  final ValueChanged<String?> onEquipmentChanged;
  final ValueChanged<bool?> onCompoundChanged;
  final VoidCallback onToggleFavorites;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                GlassChip(
                  label: 'Favorites',
                  icon: Icons.star,
                  selected: filter.favoritesOnly,
                  onTap: onToggleFavorites,
                ),
                const SizedBox(width: AppSpacing.sm),
                GlassChip(
                  label: 'Compound',
                  selected: filter.compound == true,
                  onTap: () => onCompoundChanged(
                    filter.compound == true ? null : true,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GlassChip(
                  label: 'Isolation',
                  selected: filter.compound == false,
                  onTap: () => onCompoundChanged(
                    filter.compound == false ? null : false,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: _EquipmentDropdown(
              value: filter.equipment,
              onChanged: onEquipmentChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact equipment filter dropdown.
class _EquipmentDropdown extends StatelessWidget {
  const _EquipmentDropdown({required this.value, required this.onChanged});

  static const _equipment = [
    'Barbell',
    'Dumbbell',
    'Kettlebell',
    'Cable',
    'Machine',
    'Bodyweight',
    'Resistance Band',
    'TRX',
    'Cardio',
    'Foam Roller',
    'Other',
  ];

  final String? value;
  final ValueChanged<String?> onChanged;

  Future<void> _open(BuildContext context) async {
    final picked = await showForgeSelectionDialog<String>(
      context,
      title: 'Equipment',
      selected: value ?? '',
      options: [
        const ForgeSelectionOption(
          label: 'All equipment',
          value: '',
          icon: Icons.check_circle_outline,
        ),
        for (final name in _equipment)
          ForgeSelectionOption(label: name, value: name),
      ],
    );
    if (picked != null && context.mounted) {
      onChanged(picked.isEmpty ? null : picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return GlassIconButton(
      icon: Icons.tune,
      tooltip: 'Equipment',
      semanticLabel: 'Equipment',
      color: value == null ? colors.onSurfaceTertiary : colors.primary,
      onPressed: () => _open(context),
    );
  }
}

/// Empty library state.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasActiveFilter, required this.onClear});

  final bool hasActiveFilter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GlassEmptyState(
      icon: Icons.search_off,
      title: hasActiveFilter
          ? 'No exercises match your filters'
          : 'No exercises yet',
      message: hasActiveFilter
          ? 'Try clearing your filters to see the full library.'
          : 'Create your first exercise to start building a workout.',
      action: hasActiveFilter
          ? GlassButton(
              label: 'Clear filters',
              variant: GlassButtonVariant.outlined,
              icon: Icons.filter_alt_off,
              onPressed: onClear,
            )
          : null,
    );
  }
}

/// Sections of exercises: favorites, recent, then A-Z groups.
class _LibraryList extends StatefulWidget {
  const _LibraryList({
    required this.exercises,
    required this.favorites,
    required this.groupedByLetter,
    required this.showSections,
    required this.query,
    required this.onTap,
    required this.onEdit,
    required this.onToggleFavorite,
    required this.onArchive,
    required this.onDelete,
  });

  final List<Exercise> exercises;
  final List<Exercise> favorites;
  final bool groupedByLetter;
  final bool showSections;
  final String query;
  final ValueChanged<Exercise> onTap;
  final ValueChanged<Exercise> onEdit;
  final ValueChanged<Exercise> onToggleFavorite;
  final ValueChanged<Exercise> onArchive;
  final ValueChanged<Exercise> onDelete;

  @override
  State<_LibraryList> createState() => _LibraryListState();
}

class _LibraryListState extends State<_LibraryList> {
  final Map<String, GlobalKey> _sectionKeys = {};

  List<_Section> _buildSections() {
    final sections = <_Section>[];

    if (widget.showSections) {
      final recent = widget.exercises
          .where((exercise) => exercise.lastUsedAt != null)
          .toList()
        ..sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));
      if (recent.isNotEmpty) {
        sections.add(_Section(title: 'Recent', exercises: recent));
      }

      final favorites = widget.exercises
          .where((exercise) => exercise.favorite)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (favorites.isNotEmpty) {
        sections.add(_Section(title: 'Favorites', exercises: favorites));
      }

      final grouped = <String, List<Exercise>>{};
      for (final exercise in widget.exercises) {
        final letter = _letterOf(exercise.name);
        grouped.putIfAbsent(letter, () => []).add(exercise);
      }
      for (final letter in grouped.keys.toList()..sort()) {
        sections.add(_Section(title: letter, exercises: grouped[letter]!));
      }
    } else {
      sections.add(_Section(title: '', exercises: widget.exercises));
    }

    return sections;
  }

  String _letterOf(String name) {
    final first = name.trim().isEmpty ? '#' : name.trim()[0].toUpperCase();
    return RegExp(r'^[A-Z]$').hasMatch(first) ? first : '#';
  }

  void _scrollTo(String letter) {
    final key = _sectionKeys[letter];
    if (key == null) return;
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    final letters = widget.showSections && widget.groupedByLetter
        ? sections.where((s) => s.title.length == 1).map((s) => s.title).toList()
        : const <String>[];

    for (final letter in letters) {
      _sectionKeys.putIfAbsent(letter, () => GlobalKey());
    }
    _sectionKeys.removeWhere((key, _) => !letters.contains(key));

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: 96,
          ),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            final key = section.title.length == 1
                ? _sectionKeys[section.title]
                : null;
            return Column(
              key: key,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (section.title.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      section.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).forgeColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  if (section.title.length == 1)
                    GlassDivider(),
                ],
                for (final exercise in section.exercises)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ExerciseCard(
                      exercise: exercise,
                      query: widget.query,
                      onTap: () => widget.onTap(exercise),
                      onToggleFavorite: () => widget.onToggleFavorite(exercise),
                      onEdit: () => widget.onEdit(exercise),
                      onArchive: () => widget.onArchive(exercise),
                      onDelete: () => widget.onDelete(exercise),
                    ),
                  ),
              ],
            );
          },
        ),
        if (letters.isNotEmpty)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _AlphabetRail(
              letters: letters,
              onTap: _scrollTo,
            ),
          ),
      ],
    );
  }
}

/// A named group of exercises.
class _Section {
  const _Section({required this.title, required this.exercises});

  final String title;
  final List<Exercise> exercises;
}

/// Vertical A-Z rail that jumps to a letter section.
class _AlphabetRail extends StatelessWidget {
  const _AlphabetRail({required this.letters, required this.onTap});

  final List<String> letters;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (details) {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final letter in letters)
              GlassPressable(
                onTap: () => onTap(letter),
                semanticLabel: 'Jump to $letter',
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  child: Text(
                    letter,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
