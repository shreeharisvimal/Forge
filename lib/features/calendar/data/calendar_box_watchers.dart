// Calendar data access for the Forge application.
//
// Low-level Riverpod streams that re-emit whenever the Hive boxes the
// calendar reads change. Hive boxes do not notify plain providers, so the
// calendar read model watches these streams to stay live after every save
// from any feature (including the day-detail sheet itself).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../services/providers.dart';

/// Re-emits on every change to the calendar-day box.
final calendarBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).calendarBox.watch(),
);

/// Re-emits on every change to the weight box.
final calendarWeightBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).weightBox.watch(),
);

/// Re-emits on every change to the session box.
final calendarSessionBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).sessionBox.watch(),
);

/// Re-emits on every change to the measurement box.
final calendarMeasurementBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).measurementBox.watch(),
);

/// Re-emits on every change to the personal-record box.
final calendarPrBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).prBox.watch(),
);

/// Re-emits on every change to the append-only PR-event box.
final calendarPrEventsBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).prEventsBox.watch(),
);

/// Re-emits on every change to the split box.
final calendarSplitBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).splitBox.watch(),
);
