// Canonical exercise categories for the Forge application.
//
// Shared by the seed catalog and the library UI (filter chips, editors).
// Values are stored on [Exercise] as human-readable strings, so new
// categories only require adding a constant here - never a migration.
library;

/// Canonical muscle group names used across the library.
abstract final class MuscleGroups {
  MuscleGroups._();

  static const String chest = 'Chest';
  static const String back = 'Back';
  static const String shoulders = 'Shoulders';
  static const String frontDelts = 'Front Delts';
  static const String sideDelts = 'Side Delts';
  static const String rearDelts = 'Rear Delts';
  static const String biceps = 'Biceps';
  static const String triceps = 'Triceps';
  static const String forearms = 'Forearms';
  static const String abs = 'Abs';
  static const String obliques = 'Obliques';
  static const String lowerBack = 'Lower Back';
  static const String glutes = 'Glutes';
  static const String quadriceps = 'Quadriceps';
  static const String hamstrings = 'Hamstrings';
  static const String calves = 'Calves';
  static const String fullBody = 'Full Body';
  static const String cardio = 'Cardio';
  static const String mobility = 'Mobility';

  /// All canonical groups, in display order.
  static const List<String> all = [
    chest,
    back,
    shoulders,
    frontDelts,
    sideDelts,
    rearDelts,
    biceps,
    triceps,
    forearms,
    abs,
    obliques,
    lowerBack,
    glutes,
    quadriceps,
    hamstrings,
    calves,
    fullBody,
    cardio,
    mobility,
  ];
}

/// Canonical equipment names used across the library.
abstract final class Equipment {
  Equipment._();

  static const String barbell = 'Barbell';
  static const String dumbbell = 'Dumbbell';
  static const String kettlebell = 'Kettlebell';
  static const String cable = 'Cable';
  static const String machine = 'Machine';
  static const String bodyweight = 'Bodyweight';
  static const String resistanceBand = 'Resistance Band';
  static const String trx = 'TRX';
  static const String cardioMachine = 'Cardio';
  static const String foamRoller = 'Foam Roller';
  static const String other = 'Other';

  /// All canonical equipment types, in display order.
  static const List<String> all = [
    barbell,
    dumbbell,
    kettlebell,
    cable,
    machine,
    bodyweight,
    resistanceBand,
    trx,
    cardioMachine,
    foamRoller,
    other,
  ];
}
