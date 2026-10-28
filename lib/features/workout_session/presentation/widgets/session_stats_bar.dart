// Live session stats bar for the active workout.
//
// A compact glass strip showing the running set count, volume and elapsed
// time, plus a pause/resume toggle for the session clock.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/forge_design.dart';
import '../../../../services/providers.dart';
import '../../domain/session_formatters.dart';
import '../../providers/session_providers.dart';

/// The live stats strip at the top of the active stage.
class SessionStatsBar extends ConsumerWidget {
  /// Creates the stats bar.
  const SessionStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(liveSessionStatsProvider);
    final elapsed = ref.watch(sessionElapsedProvider);
    final session = ref.watch(activeSessionProvider).value;
    final unit = SessionWeightUnit.fromSettings(
      ref.watch(settingsProvider).weightUnit,
    );

    return GlassContainer(
      decoration: GlassDecoration(
        color: context.forgeColors.glass,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: const GlassBorder(),
      ),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _Stat(label: 'Sets', value: '${stats.sets}'),
          _Stat(label: 'Volume', value: SessionFormatters.volume(stats.volume, unit)),
          Expanded(
            child: _Stat(
              label: 'Time',
              value: SessionFormatters.shortDuration(elapsed),
              valueColor: context.forgeColors.primary,
            ),
          ),
          GlassIconButton(
            icon: (session?.isTimerPaused ?? false)
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            variant: GlassIconButtonVariant.glass,
            size: AppIconSize.small,
            semanticLabel: (session?.isTimerPaused ?? false)
                ? 'Resume session timer'
                : 'Pause session timer',
            onPressed: () {
              final controller = ref.read(activeSessionProvider.notifier);
              if (session?.isTimerPaused ?? false) {
                controller.resumeTimer();
              } else {
                controller.pauseTimer();
              }
            },
          ),
        ],
      ),
    );
  }
}

/// A single stat column within the strip.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceMuted),
        ),
        SizedBox(height: AppSpacing.xxs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: valueColor ?? colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
