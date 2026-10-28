// Workouts hub providers for the Forge application.
//
// Small reactive read models the workouts tab composes: the workout-template
// list with its box-change stream. Everything else the hub renders reuses the
// shared repositories and the workout-session feature's providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../models/workout_template.dart';
import '../../../services/providers.dart';

/// Re-emits on every change to the template box.
final templateBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).templateBox.watch(),
);

/// All workout templates, alphabetically sorted.
final workoutTemplatesProvider = Provider<List<WorkoutTemplate>>((ref) {
  ref.watch(templateBoxChangesProvider);
  return ref.watch(workoutTemplateRepositoryProvider).sorted();
});
