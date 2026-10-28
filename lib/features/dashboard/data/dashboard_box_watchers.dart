// Dashboard data access for the Forge application.
//
// Low-level Riverpod streams that re-emit whenever the Hive boxes the
// dashboard reads change. Hive boxes do not notify plain providers, so each
// dashboard provider watches the relevant stream to stay reactive after
// every save from any feature.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../services/providers.dart';

/// Re-emits on every change to the weight box.
final weightBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).weightBox.watch(),
);

/// Re-emits on every change to the session box.
final sessionBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).sessionBox.watch(),
);

/// Re-emits on every change to the split box.
final splitBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).splitBox.watch(),
);

/// Re-emits on every change to the personal-record box.
final prBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).prBox.watch(),
);

/// Re-emits on every change to the exercise-history box.
final historyBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).historyBox.watch(),
);

/// Re-emits on every change to the measurement box.
final measurementBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).measurementBox.watch(),
);
