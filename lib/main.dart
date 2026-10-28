// Application entry point for the Forge application.
//
// Bootstraps storage before any widget is built: the Hive-backed
// [DatabaseService] is initialized, first-launch seed data is written, and
// the resulting instance is injected through [databaseServiceProvider]. The
// ProviderScope then composes the GoRouter navigation and Material 3 dark
// AMOLED theme. If storage cannot be opened the app shows a minimal error
// screen instead of a white crash.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design/colors/forge_accent_palettes.dart';
import 'core/design/colors/forge_colors.dart';
import 'core/design/theme/forge_theme.dart';
import 'core/overlays/forge_overlays.dart';
import 'core/router/app_router.dart';
import 'database/database_service.dart';
import 'database/seeder.dart';
import 'features/settings/providers/settings_providers.dart';
import 'services/providers.dart';
import 'services/repositories/exercise_repository.dart';

Future<void> main() async {
  // Ensure the Flutter binding is ready before any platform channels run.
  WidgetsFlutterBinding.ensureInitialized();

  final DatabaseService databaseService;
  try {
    databaseService = await DatabaseService.initialize();
    final seeder = Seeder(
      databaseService: databaseService,
      exerciseRepository: HiveExerciseRepository(databaseService.exerciseBox),
    );
    await seeder.runIfNeeded();
  } catch (error) {
    runApp(ProviderScope(child: _BootstrapError(message: '$error')));
    return;
  }

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(databaseService),
      ],
      child: const ForgeApp(),
    ),
  );
}

/// Root widget of the Forge application.
///
/// Composes the provider scope, router and themed material app into a
/// single widget tree. The effective theme resolves from the persisted
/// settings (mode, accent, AMOLED and dynamic colors); watching the settings
/// provider makes the whole app re-theme the moment any preference changes.
class ForgeApp extends ConsumerWidget {
  /// Creates the root [ForgeApp] widget.
  const ForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the shared router instance so navigation config stays in sync.
    final router = ref.watch(routerProvider);

    // Keep app-wide services in sync with the persisted preferences.
    ref.watch(settingsEffectsProvider);

    final settings = ref.watch(settingsProvider);
    final palette = ForgeAccentPalettes.byKey(settings.accentColor);
    final themeMode = switch (settings.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return MaterialApp.router(
      title: 'Forge',
      debugShowCheckedModeBanner: false,
      color: ForgeColors.background,
      theme: ForgeTheme.light(
        palette: palette,
        dynamicColors: settings.dynamicColors,
      ),
      darkTheme: ForgeTheme.dark(
        palette: palette,
        amoled: settings.amoledMode,
        dynamicColors: settings.dynamicColors,
      ),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // The overlay layer always sits above the navigator so loading,
        // toast, success, error and progress feedback is globally visible.
        return ForgeOverlayHost(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

/// Minimal fallback screen shown when storage initialization fails.
///
/// Kept deliberately simple — no theme, router or providers — so it works
/// even when the reason for the failure is missing dependencies.
class _BootstrapError extends StatelessWidget {
  /// Creates the bootstrap error screen.
  const _BootstrapError({required this.message});

  /// The failure message surfaced from storage initialization.
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 16),
              const Text('Forge could not start.'),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
