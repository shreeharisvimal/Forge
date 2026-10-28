// Exercise repository for the Forge application.
//
// Persistence and queries for the [Exercise] library.
library;

import '../../models/exercise.dart';
import 'base_repository.dart';

/// Sort orders supported by the library.
enum ExerciseSort {
  /// A-Z by name.
  alphabetical,

  /// Most recently used first.
  recentlyUsed,

  /// Highest usage count first.
  mostUsed,

  /// Newest first (by creation date).
  newest,

  /// Oldest first (by creation date).
  oldest,
}

/// Query surface for the [Exercise] library.
abstract class ExerciseRepository extends BaseRepository<Exercise> {
  /// Creates a repository backed by [box].
  ExerciseRepository(super.box);

  /// The exercise whose name matches [name] (case-insensitive), or null.
  Exercise? byName(String name) {
    final needle = name.trim().toLowerCase();
    for (final exercise in all()) {
      if (exercise.name.toLowerCase() == needle) return exercise;
    }
    return null;
  }

  /// Every distinct muscle group in the library, sorted alphabetically.
  List<String> muscleGroups() =>
      all().map((exercise) => exercise.muscleGroup).toSet().toList()..sort();

  /// Every distinct equipment type in the library, sorted alphabetically.
  List<String> equipmentTypes() =>
      all().map((exercise) => exercise.equipment).toSet().toList()..sort();

  /// Every distinct tag in the library, sorted alphabetically.
  List<String> tags() {
    final result = <String>{};
    for (final exercise in all()) {
      result.addAll(exercise.tags);
    }
    return result.toList()..sort();
  }

  /// Exercises for [group], sorted by name.
  List<Exercise> byMuscleGroup(String group) {
    final result = all()
        .where((exercise) => exercise.muscleGroup == group)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  /// Exercises requiring [equipment], sorted by name.
  List<Exercise> byEquipment(String equipment) {
    final result = all()
        .where((exercise) => exercise.equipment == equipment)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  /// Compound exercises only, sorted by name.
  List<Exercise> compounds() {
    final result = all().where((exercise) => exercise.isCompound).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  /// Exercises marked as favorite, sorted by name.
  List<Exercise> favorites() {
    final result =
        all().where((exercise) => exercise.favorite).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  /// Exercises that are not archived (the visible library).
  List<Exercise> visible() =>
      all().where((exercise) => !exercise.archived).toList();

  /// Exercises whose name, muscle group, equipment, tags or notes contain
  /// [query] (case-insensitive). Empty query returns everything.
  List<Exercise> search(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return all();
    return all().where((exercise) {
      if (exercise.name.toLowerCase().contains(needle)) return true;
      if (exercise.muscleGroup.toLowerCase().contains(needle)) return true;
      if (exercise.equipment.toLowerCase().contains(needle)) return true;
      if (exercise.tags.any((tag) => tag.toLowerCase().contains(needle))) {
        return true;
      }
      return exercise.notes.toLowerCase().contains(needle);
    }).toList();
  }

  /// Exercises grouped by their first letter (A-Z), for index navigation.
  Map<String, List<Exercise>> byFirstLetter() {
    final grouped = <String, List<Exercise>>{};
    for (final exercise in visible()..sort((a, b) => a.name.compareTo(b.name))) {
      final letter =
          exercise.name.trim().isEmpty ? '#' : exercise.name[0].toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(exercise);
    }
    return grouped;
  }

  /// Sorts [exercises] by [sort] order.
  List<Exercise> sorted(List<Exercise> exercises, ExerciseSort sort) {
    final result = List<Exercise>.of(exercises);
    switch (sort) {
      case ExerciseSort.alphabetical:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case ExerciseSort.recentlyUsed:
        result.sort((a, b) {
          final ra = a.lastUsedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final rb = b.lastUsedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return rb.compareTo(ra);
        });
      case ExerciseSort.mostUsed:
        result.sort((a, b) => b.usageCount.compareTo(a.usageCount));
      case ExerciseSort.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ExerciseSort.oldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    return result;
  }

  /// Records that [exercise] was used, incrementing usage and stamping the
  /// usage timestamp.
  Future<void> recordUsage(Exercise exercise) async {
    await save(exercise.copyWith(
      usageCount: exercise.usageCount + 1,
      lastUsedAt: () => DateTime.now(),
    ));
  }
}

/// Hive-backed [ExerciseRepository].
class HiveExerciseRepository extends ExerciseRepository {
  /// Creates a repository backed by [box].
  HiveExerciseRepository(super.box);
}
