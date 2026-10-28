// Body data access for the Forge application.
//
// Low-level Riverpod streams that re-emit whenever the Hive boxes the Body
// feature reads change. Hive boxes do not notify plain providers, so each
// Body provider watches the relevant stream to stay live after every save
// from any feature.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../services/providers.dart';

/// Re-emits on every change to the measurement box.
final bodyMeasurementBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).measurementBox.watch(),
);

/// Re-emits on every change to the body-goal box.
final bodyGoalsBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).bodyGoalsBox.watch(),
);

/// Re-emits on every change to the settings box.
final bodySettingsBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).settingsBox.watch(),
);
