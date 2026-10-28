// Recovery panel for the Forge dashboard.
//
// Renders one glass progress bar per muscle bucket, showing how rested
// each area is based on recent completed sessions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../domain/dashboard_models.dart';
import '../providers/dashboard_providers.dart';

/// The muscle recovery panel.
class RecoveryPanel extends ConsumerWidget {
  /// Creates the recovery panel.
  const RecoveryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readings = ref.watch(recoveryProvider);
    if (readings.isEmpty) return const SizedBox.shrink();

    return GlassChartContainer(
      title: 'Recovery',
      subtitle: 'How rested each area is',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < readings.length; i++) ...[
            if (i > 0) SizedBox(height: AppSpacing.md),
            _RecoveryRow(reading: readings[i]),
          ],
        ],
      ),
    );
  }
}

class _RecoveryRow extends StatelessWidget {
  const _RecoveryRow({required this.reading});

  final MuscleRecovery reading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    final percent = reading.percent.clamp(0.0, 1.0);
    final percentLabel = (percent * 100).round();

    return Semantics(
      label: '${reading.group.label} recovery $percentLabel percent',
      child: Row(
        children: [
          SizedBox(
            width: AppSpacing.huge * 1.6,
            child: Text(
              reading.group.label,
              style: textTheme.labelLarge?.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
          Expanded(
            child: GlassProgressBar(
              value: percent,
              height: AppSpacing.sm,
              color: colors.primary,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          SizedBox(
            width: AppSpacing.huge * 1.1,
            child: Text(
              '$percentLabel%',
              textAlign: TextAlign.right,
              style: textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
