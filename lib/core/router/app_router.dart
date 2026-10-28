// Router configuration for the Forge application.
//
// Builds the application's GoRouter using a StatefulShellRoute so the five
// top-level destinations share a persistent bottom navigation bar. Each
// branch keeps its own navigation stack via an indexed stack.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/body/body_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/exercises/presentation/exercise_detail_screen.dart';
import '../../features/exercises/presentation/exercise_edit_screen.dart';
import '../../features/exercises/presentation/exercise_library_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splits/presentation/split_list_screen.dart';
import '../../features/workout_session/presentation/workout_session_screen.dart';
import '../../features/workouts/workouts_screen.dart';
import '../design/animations/animation_config.dart';
import '../design/animations/glass_page_transitions.dart';
import '../design/tokens/duration_tokens.dart';
import '../widgets/forge_shell.dart';
import 'app_route_paths.dart';

/// Riverpod provider for the application [GoRouter].
///
/// Exposed as a provider so any widget can navigate by watching it, and so
/// the router instance can be shared with `MaterialApp.router`.
final routerProvider = Provider<GoRouter>((ref) {
  return AppRouter.build();
});

/// Builds the navigation tree for Forge.
abstract final class AppRouter {
  AppRouter._();

  /// Creates the root [GoRouter] with persistent shell navigation.
  static GoRouter build() {
    return GoRouter(
      initialLocation: AppRoutePaths.dashboard,
      // Any attempt to reach the root path lands on the dashboard tab.
      redirect: (context, state) {
        if (state.matchedLocation == '/') {
          return AppRoutePaths.dashboard;
        }
        return null;
      },
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return ForgeShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutePaths.dashboard,
                  name: AppRouteNames.dashboard,
                  builder: (context, state) => const DashboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutePaths.calendar,
                  name: AppRouteNames.calendar,
                  builder: (context, state) => const CalendarScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutePaths.workouts,
                  name: AppRouteNames.workouts,
                  builder: (context, state) => const WorkoutsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutePaths.progress,
                  name: AppRouteNames.progress,
                  builder: (context, state) => const ProgressScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutePaths.body,
                  name: AppRouteNames.body,
                  builder: (context, state) => const BodyScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutePaths.settings,
                  name: AppRouteNames.settings,
                  builder: (context, state) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),
        // Full-screen exercise detail and editor, pushed over the shell.
        // These use an explicit glass page so they animate with the design
        // system's page duration instead of the Material default.
        GoRoute(
          path: AppRoutePaths.exerciseDetail,
          name: AppRouteNames.exerciseDetail,
          pageBuilder: (context, state) => _glassPage(
            ExerciseDetailScreen(
              exerciseId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.exerciseLibrary,
          name: AppRouteNames.exerciseLibrary,
          pageBuilder: (context, state) =>
              _glassPage(const ExerciseLibraryScreen()),
        ),
        GoRoute(
          path: AppRoutePaths.exerciseEdit,
          name: AppRouteNames.exerciseEdit,
          pageBuilder: (context, state) =>
              _glassPage(const ExerciseEditScreen()),
        ),
        GoRoute(
          path: AppRoutePaths.splits,
          name: AppRouteNames.splits,
          pageBuilder: (context, state) =>
              _glassPage(const SplitListScreen()),
        ),
        GoRoute(
          path: AppRoutePaths.session,
          name: AppRouteNames.session,
          pageBuilder: (context, state) =>
              _glassPage(const WorkoutSessionScreen()),
        ),
      ],
    );
  }
}

/// Builds a [Page] that shows [child] with the design system's shared-axis
/// glass transition and page duration (see [AppDuration.page]). When
/// animations are disabled the transition is instant.
Page<T> _glassPage<T>(Widget child) {
  final duration = AnimationConfig.isDisabled ? Duration.zero : AppDuration.page;
  return CustomTransitionPage<T>(
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return GlassPageTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      );
    },
    child: child,
  );
}
