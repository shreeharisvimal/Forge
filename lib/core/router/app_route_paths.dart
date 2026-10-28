// Route definitions for the Forge application.
//
// Centralized route paths and names so navigation calls stay in sync with
// the GoRouter configuration and never rely on magic strings.
library;

/// Route paths for the Forge application.
abstract final class AppRoutePaths {
  AppRoutePaths._();

  /// Dashboard (home) tab.
  static const String dashboard = '/dashboard';

  /// Calendar tab.
  static const String calendar = '/calendar';

  /// Workouts (fitness center) tab.
  static const String workouts = '/workouts';

  /// Exercise library screen.
  static const String exerciseLibrary = '/workouts/library';

  /// Training splits management screen.
  static const String splits = '/workouts/splits';

  /// In-progress workout session (preparation/active/summary).
  static const String session = '/workout-session';

  /// Exercise detail screen.
  static const String exerciseDetail = '/workouts/exercises/:id';

  /// Create/edit exercise screen.
  static const String exerciseEdit = '/workouts/exercises/edit';

  /// Progress tab.
  static const String progress = '/progress';

  /// Body measurements tab.
  static const String body = '/body';

  /// Settings tab.
  static const String settings = '/settings';
}

/// Route names for the Forge application.
///
/// Used for named navigation (`context.goNamed`) so route references
/// survive path changes.
abstract final class AppRouteNames {
  AppRouteNames._();

  /// Name of the dashboard route.
  static const String dashboard = 'dashboard';

  /// Name of the calendar route.
  static const String calendar = 'calendar';

  /// Name of the workouts route.
  static const String workouts = 'workouts';

  /// Name of the exercise library route.
  static const String exerciseLibrary = 'exerciseLibrary';

  /// Name of the training splits route.
  static const String splits = 'splits';

  /// Name of the workout session route.
  static const String session = 'session';

  /// Name of the exercise detail route.
  static const String exerciseDetail = 'exerciseDetail';

  /// Name of the create/edit exercise route.
  static const String exerciseEdit = 'exerciseEdit';

  /// Name of the progress route.
  static const String progress = 'progress';

  /// Name of the body measurements route.
  static const String body = 'body';

  /// Name of the settings route.
  static const String settings = 'settings';
}
