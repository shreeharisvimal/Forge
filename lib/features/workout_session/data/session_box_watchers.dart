// Session box watchers for the Forge application.
//
// Low-level Riverpod streams that re-emit whenever the boxes the workout
// session feature reads change. Hive boxes do not notify plain providers, so
// derived providers watch the relevant stream to stay reactive.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../services/providers.dart';

/// Re-emits on every change to the session history box.
final sessionBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).sessionBox.watch(),
);

/// Re-emits on every change to the active-session box.
final activeSessionBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).activeSessionBox.watch(),
);
