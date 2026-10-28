// PR feature data access for the Forge application.
//
// Low-level Riverpod streams that re-emit whenever the Hive boxes the PR
// engine reads change. Hive boxes do not notify plain providers, so each PR
// provider watches the relevant stream to stay reactive after every save.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../services/providers.dart';

/// Re-emits on every change to the personal-record event box.
final prEventsBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).prEventsBox.watch(),
);

/// Re-emits on every change to the personal-record bests box.
final prRecordBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).prBox.watch(),
);

/// Re-emits on every change to the exercise-history box.
final prHistoryBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).historyBox.watch(),
);

/// Re-emits on every change to the session box.
final prSessionBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).sessionBox.watch(),
);

/// Re-emits on every change to the weight box.
final prWeightBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).weightBox.watch(),
);

/// Re-emits on every change to the settings box.
final prSettingsBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).settingsBox.watch(),
);
