// Workout session screen for the Forge application.
//
// Hosts the three-stage session flow (preparation, active, summary). On first
// entry the screen restores any in-progress session or launches a fresh one
// built from today's split day. The [ActiveSessionController] owns all state;
// this screen only switches between the stage widgets and the glass app bar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/forge_design.dart';
import '../domain/session_models.dart';
import '../providers/session_launch.dart';
import '../providers/session_providers.dart';
import 'widgets/active_stage.dart';
import 'widgets/preparation_stage.dart';
import 'widgets/summary_stage.dart';

/// The full workout session screen.
class WorkoutSessionScreen extends ConsumerStatefulWidget {
  /// Creates the workout session screen.
  const WorkoutSessionScreen({super.key});

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  bool _launched = false;
  bool _hadSession = false;

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(activeSessionProvider);
    final session = sessionAsync.value;

    if (session == null) {
      if (!_hadSession) _maybeLaunch();
      return const _SessionLoading();
    }
    _hadSession = true;

    final colors = Theme.of(context).forgeColors;
    return PopScope(
      canPop: session.stage != SessionStage.summary,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await ref.read(activeSessionProvider.notifier).abandon();
        if (context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              GlassAppBar(
                title: session.stage == SessionStage.summary
                    ? 'Workout summary'
                    : session.name,
                actions: const [],
              ),
              Expanded(
                child: switch (session.stage) {
                  SessionStage.preparation =>
                    PreparationStage(session: session),
                  SessionStage.active => ActiveStage(session: session),
                  SessionStage.summary => SummaryStage(session: session),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens a fresh session the first time the provider resolves to null.
  void _maybeLaunch() {
    if (_launched || ref.read(activeSessionProvider).isLoading) return;
    _launched = true;
    final launch = ref.read(sessionLaunchProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeSessionProvider.notifier).openSession(
            name: launch.name,
            plans: launch.plans,
          );
    });
  }
}

class _SessionLoading extends StatelessWidget {
  const _SessionLoading();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: GlassLoading(
          size: AppIconSize.large,
          label: 'Preparing workout...',
        ),
      ),
    );
  }
}
