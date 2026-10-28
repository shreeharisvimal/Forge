// Workout split feature for the Forge application.
//
// Riverpod state for the split management system: exposes the split list,
// the active split and the box-change stream so screens rebuild after edits.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../models/workout_split.dart';
import '../../../services/providers.dart';

/// Re-emits whenever the split box changes (Hive boxes do not notify plain
/// Riverpod providers).
final splitBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).splitBox.watch(),
);

/// All splits, newest first.
final workoutSplitsProvider = Provider<List<WorkoutSplit>>((ref) {
  ref.watch(splitBoxChangesProvider);
  return ref.watch(workoutSplitRepositoryProvider).sorted();
});

/// The split currently driving the schedule, or null.
final activeSplitProvider = Provider<WorkoutSplit?>((ref) {
  ref.watch(splitBoxChangesProvider);
  return ref.watch(workoutSplitRepositoryProvider).activeSplit;
});

/// Whether at least one split exists.
final hasSplitsProvider = Provider<bool>((ref) {
  ref.watch(splitBoxChangesProvider);
  return ref.watch(workoutSplitRepositoryProvider).count > 0;
});
