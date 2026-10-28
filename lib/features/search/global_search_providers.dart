// Global search providers for the Forge application.
//
// Composes the fuzzy search engine over the app's main datasets (exercises,
// splits, templates, performed sessions) for the global search sheet opened
// from the workouts hub. Watches every relevant box stream so results stay
// fresh after any save.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' as legacy;

import '../../core/services/search/search_engine.dart';
import '../../models/exercise.dart';
import '../../models/workout_session.dart';
import '../../models/workout_split.dart';
import '../../models/workout_template.dart';
import '../../services/providers.dart';
import '../exercises/providers/exercise_library_providers.dart';
import '../splits/providers/split_providers.dart';
import '../workout_session/data/session_box_watchers.dart';
import '../workouts/providers/workouts_providers.dart';

/// The live global search query.
final globalSearchQueryProvider = legacy.StateProvider<String>((_) => '');

/// The grouped results of a global search.
class GlobalSearchResults {
  /// Creates results.
  const GlobalSearchResults({
    this.exercises = const [],
    this.splits = const [],
    this.templates = const [],
    this.sessions = const [],
  });

  /// Matching exercises, best first.
  final List<SearchResult<Exercise>> exercises;

  /// Matching splits, best first.
  final List<SearchResult<WorkoutSplit>> splits;

  /// Matching templates, best first.
  final List<SearchResult<WorkoutTemplate>> templates;

  /// Matching performed sessions, best first.
  final List<SearchResult<WorkoutSession>> sessions;

  /// Whether any result matched.
  bool get isEmpty =>
      exercises.isEmpty &&
      splits.isEmpty &&
      templates.isEmpty &&
      sessions.isEmpty;
}

/// Searches the four datasets, best-first per section.
final globalSearchResultsProvider = Provider<GlobalSearchResults>((ref) {
  final query = ref.watch(globalSearchQueryProvider).trim();
  if (query.isEmpty) return const GlobalSearchResults();

  ref.watch(exerciseBoxChangesProvider);
  ref.watch(splitBoxChangesProvider);
  ref.watch(templateBoxChangesProvider);
  ref.watch(sessionBoxChangesProvider);

  final exerciseEngine = FuzzySearchEngine<Exercise>(
    textOf: (exercise) =>
        '${exercise.name} ${exercise.muscleGroup} ${exercise.equipment} '
        '${exercise.tags.join(' ')}',
  );
  final splitEngine = FuzzySearchEngine<WorkoutSplit>(
    textOf: (split) =>
        '${split.name} ${split.description} '
        '${split.days.map((day) => day.name).join(' ')}',
  );
  final templateEngine = FuzzySearchEngine<WorkoutTemplate>(
    textOf: (template) => template.name,
  );
  final sessionEngine = FuzzySearchEngine<WorkoutSession>(
    textOf: (session) =>
        '${session.name} ${session.exercises.map((e) => e.exerciseName).join(' ')}',
  );

  return GlobalSearchResults(
    exercises: exerciseEngine
        .search(ref.watch(exerciseRepositoryProvider).visible(), query)
        .take(8)
        .toList(),
    splits: splitEngine
        .search(ref.watch(workoutSplitRepositoryProvider).sorted(), query)
        .take(8)
        .toList(),
    templates: templateEngine
        .search(ref.watch(workoutTemplateRepositoryProvider).sorted(), query)
        .take(8)
        .toList(),
    sessions: sessionEngine
        .search(ref.watch(workoutSessionRepositoryProvider).recent(100), query)
        .take(8)
        .toList(),
  );
});
