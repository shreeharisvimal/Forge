// PR feature providers for the Forge application.
//
// Composes the repositories and domain math into the read models the PR
// widgets render: the configured formula, live per-set comparisons during a
// workout, per-exercise record history, the composite strength score and the
// celebration queue that drives the post-workout dialog. Each provider
// watches the box-change stream it reads so the UI stays live after any save.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/personal_record.dart';
import '../../../services/providers.dart';
import '../../workout_session/providers/session_providers.dart';
import '../data/pr_box_watchers.dart';
import '../data/pr_event.dart';
import '../domain/one_rep_max.dart';
import '../domain/pr_calculator.dart';
import '../domain/pr_detector.dart';
import '../domain/pr_engine.dart';
import '../domain/strength_score.dart';
import '../services/pr_sound_service.dart';

/// The PR feature's notion of "now" (test-pin-able).
final prNowProvider = Provider<DateTime>((_) => DateTime.now());

/// The configured one-rep-max formula, reactive to the settings box.
final prFormulaProvider = Provider<OneRepMaxFormula>((ref) {
  ref.watch(prSettingsBoxChangesProvider);
  return OneRepMaxFormula.fromStorageKey(
    ref.watch(settingsProvider).oneRepMaxFormula,
  );
});

/// Detects the personal records a finished session produced.
final prEngineProvider = Provider<PrEngine>((ref) {
  return PrEngine(
    personalRecordRepository: ref.watch(personalRecordRepositoryProvider),
    prEventRepository: ref.watch(prEventRepositoryProvider),
  );
});

/// Plays the short system cues that accompany PR moments.
final prSoundServiceProvider = Provider<PrSoundService>(
  (ref) => PrSoundService(),
);

/// Every personal-record event, newest first.
final prEventsProvider = Provider<List<PrEvent>>((ref) {
  ref.watch(prEventsBoxChangesProvider);
  return ref.watch(prEventRepositoryProvider).recent(200);
});

/// Personal-record events for one exercise, newest first.
final exercisePrEventsProvider =
    Provider.family<List<PrEvent>, String>((ref, exerciseId) {
  ref.watch(prEventsBoxChangesProvider);
  return ref.watch(prEventRepositoryProvider).forExercise(exerciseId);
});

/// The stored lifetime record for one exercise, or null on a fresh install.
final exerciseRecordProvider =
    Provider.family<PersonalRecord?, String>((ref, exerciseId) {
  ref.watch(prRecordBoxChangesProvider);
  return ref.watch(personalRecordRepositoryProvider).forExercise(exerciseId);
});

/// Live per-type comparisons for the in-progress exercise at [exerciseIndex].
///
/// Rebuilds whenever the session changes (every set edit) and whenever the
/// stored record changes, so a live badge appears the moment a set beats a
/// record and disappears again if the set is edited back down.
final livePrComparisonsProvider =
    Provider.family<List<PrComparison>, int>((ref, exerciseIndex) {
  final session = ref.watch(activeSessionProvider).value;
  if (session == null) return const [];
  if (exerciseIndex < 0 ||
      exerciseIndex >= session.content.exercises.length) {
    return const [];
  }
  final performed = session.content.exercises[exerciseIndex];
  final record = ref.watch(exerciseRecordProvider(performed.exerciseId));
  final formula = ref.watch(prFormulaProvider);
  return PrDetector.live(performed, record: record, formula: formula);
});

/// The Forge composite 0-100 strength score across the whole history.
final strengthScoreProvider = Provider<StrengthScore>((ref) {
  ref.watch(prRecordBoxChangesProvider);
  ref.watch(prSessionBoxChangesProvider);
  ref.watch(prWeightBoxChangesProvider);
  return StrengthScoreCalculator.calculate(
    records: ref.watch(personalRecordRepositoryProvider).all(),
    sessions: ref.watch(workoutSessionRepositoryProvider).all(),
    bodyWeightKg: ref.watch(weightRepositoryProvider).latest()?.weight ?? 0,
    now: ref.watch(prNowProvider),
  );
});

/// The events of the most recently finished session, waiting to be celebrated.
final prCelebrationProvider =
    NotifierProvider<PrCelebrationController, List<PrEvent>>(
  PrCelebrationController.new,
);

/// Owns the post-workout celebration queue.
class PrCelebrationController extends Notifier<List<PrEvent>> {
  @override
  List<PrEvent> build() => const [];

  /// Queues [events] for celebration, replacing any earlier queue.
  void celebrate(List<PrEvent> events) {
    state = List<PrEvent>.unmodifiable(events);
  }

  /// Clears the queue (the celebration was shown or dismissed).
  void dismiss() => state = const [];
}
