// Exercise library feature for the Forge application.
//
// Riverpod state for the exercise library: the filter/sort controls plus the
// derived, filtered result set. Filter state lives in a [Notifier] so the
// library screen can drive it from search, chips and menus without touching
// the repository.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../models/exercise.dart';
import '../../../services/providers.dart';
import '../../../services/repositories/exercise_repository.dart';
import '../data/exercise_reference_checker.dart';

/// The active query, filters and sort for the exercise library.
class ExerciseLibraryFilter {
  /// Creates a filter with default values.
  const ExerciseLibraryFilter({
    this.query = '',
    this.muscleGroup,
    this.equipment,
    this.compound,
    this.favoritesOnly = false,
    this.sort = ExerciseSort.alphabetical,
    this.showArchived = false,
  });

  /// Debounced search text.
  final String query;

  /// Primary muscle group filter, or null for all.
  final String? muscleGroup;

  /// Equipment filter, or null for all.
  final String? equipment;

  /// Compound/Isolation filter: null (all), true (compound), false (isolation).
  final bool? compound;

  /// When true, only starred exercises are shown.
  final bool favoritesOnly;

  /// Result ordering.
  final ExerciseSort sort;

  /// When true, archived exercises are included (management view).
  final bool showArchived;

  /// Whether any filter or search is active (drives list layout).
  bool get isActive =>
      query.isNotEmpty ||
      muscleGroup != null ||
      equipment != null ||
      compound != null ||
      favoritesOnly ||
      showArchived;

  /// Copy with the given fields replaced.
  ExerciseLibraryFilter copyWith({
    String? query,
    String? Function()? muscleGroup,
    String? Function()? equipment,
    bool? Function()? compound,
    bool? favoritesOnly,
    ExerciseSort? sort,
    bool? showArchived,
  }) {
    return ExerciseLibraryFilter(
      query: query ?? this.query,
      muscleGroup: muscleGroup != null ? muscleGroup() : this.muscleGroup,
      equipment: equipment != null ? equipment() : this.equipment,
      compound: compound != null ? compound() : this.compound,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      sort: sort ?? this.sort,
      showArchived: showArchived ?? this.showArchived,
    );
  }
}

/// Notifier owning the library's filter state.
class ExerciseLibraryFilterNotifier
    extends Notifier<ExerciseLibraryFilter> {
  @override
  ExerciseLibraryFilter build() => const ExerciseLibraryFilter();

  /// Sets the search query.
  void setQuery(String query) => state = state.copyWith(query: query);

  /// Sets the muscle group filter (null clears it).
  void setMuscleGroup(String? group) =>
      state = state.copyWith(muscleGroup: () => group);

  /// Sets the equipment filter (null clears it).
  void setEquipment(String? equipment) =>
      state = state.copyWith(equipment: () => equipment);

  /// Sets the compound/isolation filter (null clears it).
  void setCompound(bool? compound) =>
      state = state.copyWith(compound: () => compound);

  /// Toggles the favorites-only filter.
  void toggleFavoritesOnly() =>
      state = state.copyWith(favoritesOnly: !state.favoritesOnly);

  /// Sets the sort order.
  void setSort(ExerciseSort sort) => state = state.copyWith(sort: sort);

  /// Toggles whether archived exercises are shown.
  void toggleShowArchived() =>
      state = state.copyWith(showArchived: !state.showArchived);

  /// Resets every filter, keeping the sort order.
  void clearFilters() => state = ExerciseLibraryFilter(sort: state.sort);
}

/// Provider for the active library filter.
final exerciseLibraryFilterProvider =
    NotifierProvider<ExerciseLibraryFilterNotifier, ExerciseLibraryFilter>(
  ExerciseLibraryFilterNotifier.new,
);

/// Re-emits whenever the exercise box changes, so derived providers rebuild
/// after any save/delete (Hive boxes do not notify plain Riverpod providers).
final exerciseBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).exerciseBox.watch(),
);

/// The exercises matching the active filter, in the chosen order.
final exerciseLibraryResultsProvider =
    Provider<List<Exercise>>((ref) {
  ref.watch(exerciseBoxChangesProvider);
  final repository = ref.watch(exerciseRepositoryProvider);
  final filter = ref.watch(exerciseLibraryFilterProvider);

  var exercises =
      filter.showArchived ? repository.all() : repository.visible();

  exercises = exercises.where((exercise) {
    if (filter.favoritesOnly && !exercise.favorite) return false;
    if (filter.muscleGroup != null &&
        exercise.muscleGroup != filter.muscleGroup) {
      return false;
    }
    if (filter.equipment != null && exercise.equipment != filter.equipment) {
      return false;
    }
    if (filter.compound != null && exercise.isCompound != filter.compound) {
      return false;
    }
    if (filter.query.isNotEmpty) {
      return _matchesQuery(exercise, filter.query);
    }
    return true;
  }).toList();

  return repository.sorted(exercises, filter.sort);
});

/// Case-insensitive search across name, muscle group, equipment, tags, notes.
bool _matchesQuery(Exercise exercise, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  if (exercise.name.toLowerCase().contains(needle)) return true;
  if (exercise.muscleGroup.toLowerCase().contains(needle)) return true;
  if (exercise.equipment.toLowerCase().contains(needle)) return true;
  if (exercise.tags.any((tag) => tag.toLowerCase().contains(needle))) {
    return true;
  }
  return exercise.notes.toLowerCase().contains(needle);
}

/// Reference checker wired to the application repositories.
final exerciseReferenceCheckerProvider = Provider<ExerciseReferenceChecker>(
  (ref) => ExerciseReferenceChecker(
    workoutRepository: ref.watch(workoutRepositoryProvider),
    workoutTemplateRepository: ref.watch(workoutTemplateRepositoryProvider),
    workoutSessionRepository: ref.watch(workoutSessionRepositoryProvider),
    personalRecordRepository: ref.watch(personalRecordRepositoryProvider),
    exerciseHistoryRepository: ref.watch(exerciseHistoryRepositoryProvider),
  ),
);
