// PR celebration host for the Forge application.
//
// Renders nothing; its job is timing. It watches the celebration queue and
// presents the [GlassCelebrationDialog] exactly once when a finished session
// leaves new records behind. Placed once inside the summary stage, it keeps
// the dialog from re-firing on rebuilds while leaving the queue intact so the
// summary's records section can read it until the workout is dismissed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/providers.dart';
import '../../workout_session/domain/session_formatters.dart';
import '../providers/pr_providers.dart';
import '../widgets/glass_celebration_dialog.dart';

/// Presents the celebration dialog once per finished session.
class PrCelebrationHost extends ConsumerStatefulWidget {
  /// Creates a celebration host.
  const PrCelebrationHost({super.key});

  @override
  ConsumerState<PrCelebrationHost> createState() => _PrCelebrationHostState();
}

class _PrCelebrationHostState extends ConsumerState<PrCelebrationHost> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  @override
  void didUpdateWidget(covariant PrCelebrationHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeShow();
  }

  void _maybeShow() {
    if (_shown || !mounted) return;
    final events = ref.read(prCelebrationProvider);
    if (events.isEmpty) return;
    _shown = true;
    final unit = SessionWeightUnit.fromSettings(
      ref.read(settingsProvider).weightUnit,
    );
    GlassCelebrationDialog.show(
      context,
      events: events,
      unit: unit,
      sound: ref.read(prSoundServiceProvider),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
