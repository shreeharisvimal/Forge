// Body composition section for the Forge application.
//
// The latest fat/lean mass split: body-fat percentage, fat mass and lean
// mass, plus the change since the previous composition reading. Renders as a
// GlassStatisticCard trio. Pure presentation over [BodyComposition].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../providers/body_providers.dart';

/// The fat/lean composition cards.
class BodyCompositionSection extends ConsumerWidget {
  /// Creates the composition section.
  const BodyCompositionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(bodySnapshotProvider);
    final settings = ref.watch(bodySettingsProvider);

    final latest = snapshot.composition.isEmpty
        ? null
        : snapshot.composition.last;
    if (latest == null) return const SizedBox.shrink();
    final bodyFat = latest.bodyFat;
    if (latest.weight == null || bodyFat == null) {
      return const SizedBox.shrink();
    }

    final previous = snapshot.composition.length >= 2
        ? snapshot.composition[snapshot.composition.length - 2]
        : null;

    final prevBodyFat = previous?.bodyFat;
    final prevFatMass = previous?.bodyFatMass;
    final prevLeanMass = previous?.leanMass;
    final bodyFatMass = latest.bodyFatMass;
    final leanMass = latest.leanMass;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth >= 640 ? 3 : 1;
        final width = (constraints.maxWidth - AppSpacing.md * (crossCount - 1)) /
            crossCount;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: width,
              child: GlassStatisticCard(
                title: 'Body fat',
                value: bodyFat,
                unit: '%',
                delta: prevBodyFat == null ? null : bodyFat - prevBodyFat,
                deltaLabel: 'vs last',
                icon: Icons.percent_rounded,
              ),
            ),
            SizedBox(
              width: width,
              child: GlassStatisticCard(
                title: 'Fat mass',
                value: bodyFatMass ?? 0,
                unit: settings.weightUnit,
                delta: prevFatMass == null
                    ? null
                    : (bodyFatMass ?? 0) - prevFatMass,
                deltaLabel: 'vs last',
                icon: Icons.water_drop_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: GlassStatisticCard(
                title: 'Lean mass',
                value: leanMass ?? 0,
                unit: settings.weightUnit,
                delta: prevLeanMass == null ? null : (leanMass ?? 0) - prevLeanMass,
                deltaLabel: 'vs last',
                icon: Icons.fitness_center_rounded,
              ),
            ),
          ],
        );
      },
    );
  }
}
