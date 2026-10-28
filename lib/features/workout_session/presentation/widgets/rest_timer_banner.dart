// Rest timer banner for the active workout.
//
// Shown while a rest timer is running or paused: a live countdown with a
// progress fill and pause/resume + skip controls. Disappears when idle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/forge_design.dart';
import '../../domain/session_formatters.dart';
import '../../providers/session_providers.dart';

/// The live rest timer banner.
class RestTimerBanner extends ConsumerWidget {
  /// Creates the rest timer banner.
  const RestTimerBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(restTimerProvider);
    if (!state.active) return const SizedBox.shrink();

    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(activeSessionProvider.notifier);
    final progress = state.total.inMilliseconds == 0
        ? 0.0
        : (state.remaining.inMilliseconds / state.total.inMilliseconds)
            .clamp(0.0, 1.0);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: GlassDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: GlassBorder(color: colors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          GlassContainer(
            width: AppSpacing.huge,
            height: AppSpacing.huge,
            borderRadius: BorderRadius.circular(AppRadius.extraLarge),
            decoration: GlassDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.extraLarge),
              border: const GlassBorder(),
            ),
            child: Center(
              child: Icon(
                Icons.timer_rounded,
                size: AppIconSize.medium,
                color: colors.primary,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.paused ? 'Rest paused' : 'Rest',
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  SessionFormatters.clock(state.remaining.inSeconds),
                  style: textTheme.headlineSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                GlassProgressBar(value: progress, height: 5),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          GlassIconButton(
            icon: state.paused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            variant: GlassIconButtonVariant.glass,
            size: AppIconSize.small,
            semanticLabel: state.paused ? 'Resume rest' : 'Pause rest',
            onPressed: state.paused ? controller.resumeRest : controller.pauseRest,
          ),
          SizedBox(width: AppSpacing.sm),
          GlassIconButton(
            icon: Icons.skip_next_rounded,
            variant: GlassIconButtonVariant.glass,
            size: AppIconSize.small,
            semanticLabel: 'Skip rest',
            onPressed: controller.skipRest,
          ),
        ],
      ),
    );
  }
}
