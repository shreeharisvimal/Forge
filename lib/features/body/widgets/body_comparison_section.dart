// Body comparison section for the Forge application.
//
// Latest-versus-previous delta cards for the headline fields. Pure
// presentation over [BodyComparisonEntry]; the delta direction colors follow
// each field's preferred direction (reduction vs growth).
library;

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';
import '../../../models/settings_model.dart';
import '../domain/body_measurement_fields.dart';
import '../domain/body_measurement_models.dart';
import '../presentation/body_formatters.dart';

/// The latest-versus-previous comparison grid.
class BodyComparisonSection extends StatelessWidget {
  /// Creates the comparison section.
  const BodyComparisonSection({
    super.key,
    required this.entries,
    required this.settings,
  });

  /// The field deltas to render.
  final List<BodyComparisonEntry> entries;

  /// The current settings (units).
  final SettingsModel settings;

  @override
  Widget build(BuildContext context) {
    final fields = BodyField.headlineFields
        .map((field) => entries.where((e) => e.field == field).firstOrNull)
        .whereType<BodyComparisonEntry>()
        .toList();

    if (fields.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth >= 640 ? 4 : 2;
        final width = (constraints.maxWidth - AppSpacing.md * (crossCount - 1)) /
            crossCount;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final entry in fields)
              SizedBox(
                width: width,
                child: _ComparisonCard(entry: entry, settings: settings),
              ),
          ],
        );
      },
    );
  }
}

/// A single latest-vs-previous delta card.
class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.entry, required this.settings});

  final BodyComparisonEntry entry;
  final SettingsModel settings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final field = entry.field;
    final goodDirection = field.prefersReduction ? -1 : 1;

    final Color deltaColor;
    if (!entry.hasData) {
      deltaColor = colors.onSurfaceMuted;
    } else {
      final moving = (entry.delta ?? 0) * goodDirection;
      deltaColor = moving > 0
          ? colors.success
          : moving < 0
              ? colors.danger
              : colors.onSurfaceMuted;
    }

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: AppSpacing.md.all,
      decoration: GlassDecoration(
        color: colors.glass,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: const GlassBorder(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: colors.onSurfaceMuted),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            entry.latest == null
                ? '—'
                : BodyFormatters.valueWithUnit(
                    entry.latest!,
                    field,
                    settings,
                  ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              if (entry.hasData) ...[
                Icon(
                  (entry.delta ?? 0) >= 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: AppIconSize.extraSmall,
                  color: deltaColor,
                ),
                SizedBox(width: AppSpacing.xxs),
              ],
              Expanded(
                child: Text(
                  entry.hasData
                      ? BodyFormatters.deltaWithUnit(
                          entry.delta!,
                          field,
                          settings,
                        )
                      : 'vs last',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: deltaColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
