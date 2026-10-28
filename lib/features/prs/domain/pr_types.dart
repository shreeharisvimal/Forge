// PR domain types for the Forge application.
//
// The vocabulary of the Personal Record engine: the kinds of records that
// can be tracked and the outcome of a comparison. Kept free of Flutter and
// Riverpod imports so the whole engine stays unit-testable without a widget
// tree. The one-rep-max formulas live in `one_rep_max.dart` and the
// strength-score systems in `strength_score.dart`.
library;

/// The kinds of personal records the engine tracks.
enum PrType {
  /// Heaviest single completed lift.
  heaviestWeight,

  /// Most repetitions in a single completed set.
  mostReps,

  /// Highest estimated one-rep max.
  estimatedOneRM,

  /// Highest volume (weight x reps) in a single session.
  bestVolume,

  /// Longest isometric hold in seconds.
  ///
  /// Future-proof: emitted only once a set carries a hold measurement.
  longestHold,

  /// Fastest time for a benchmark effort.
  ///
  /// Future-proof: emitted only once a set carries a time measurement.
  bestTime;

  /// Human-readable label, e.g. "Heaviest lift".
  String get label => switch (this) {
        PrType.heaviestWeight => 'Heaviest lift',
        PrType.mostReps => 'Most reps',
        PrType.estimatedOneRM => 'Estimated 1RM',
        PrType.bestVolume => 'Best volume',
        PrType.longestHold => 'Longest hold',
        PrType.bestTime => 'Best time',
      };

  /// Icon name resolved by the presentation layer.
  String get iconName => switch (this) {
        PrType.heaviestWeight => 'scale',
        PrType.mostReps => 'numbers',
        PrType.estimatedOneRM => 'bolt',
        PrType.bestVolume => 'layers',
        PrType.longestHold => 'schedule',
        PrType.bestTime => 'timer',
      };

  /// The unit suffix shown next to values of this type.
  String get unitLabel => switch (this) {
        PrType.heaviestWeight => 'weight',
        PrType.mostReps => 'reps',
        PrType.estimatedOneRM => '1RM',
        PrType.bestVolume => 'volume',
        PrType.longestHold => 's',
        PrType.bestTime => 's',
      };
}

/// The outcome of comparing a candidate value against a previous best.
enum PrStatus {
  /// The candidate beats the previous best (or is the first ever).
  newPr,

  /// The candidate matches the previous best exactly.
  tiedPr,

  /// The candidate does not beat the previous best.
  noPr,
}

/// Whether a [PrStatus.newPr] was a first-ever record, a session best or a
/// new lifetime record.
enum PrScope {
  /// The very first record for the exercise.
  firstEver,

  /// Beats the best within the current session but not the lifetime record.
  session,

  /// Beats the previous lifetime record.
  lifetime,
}
