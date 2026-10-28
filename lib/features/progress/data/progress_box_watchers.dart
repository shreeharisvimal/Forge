// Progress feature data access for the Forge application.
//
// Low-level Riverpod streams that re-emit whenever the Hive boxes the
// Progress analytics read change. Hive boxes do not notify plain providers,
// so every Progress provider watches the relevant stream to stay live after
// any save from any feature.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../services/providers.dart';

/// Re-emits on every change to the workout-session box.
final progressSessionBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).sessionBox.watch(),
);

/// Re-emits on every change to the weigh-in box.
final progressWeightBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).weightBox.watch(),
);

/// Re-emits on every change to the personal-record event box.
final progressPrEventsBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).prEventsBox.watch(),
);

/// Re-emits on every change to the personal-record bests box.
final progressRecordBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).prBox.watch(),
);

/// Re-emits on every change to the body-goal box.
final progressGoalsBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).bodyGoalsBox.watch(),
);
