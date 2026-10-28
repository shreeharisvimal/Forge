// Motivation panel for the Forge dashboard.
//
// Shows the quote of the day with a soft animated entrance. The quote
// library holds 300+ entries and rotates deterministically by date.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../providers/dashboard_providers.dart';

/// The daily quote panel.
class MotivationPanel extends ConsumerWidget {
  /// Creates the motivation panel.
  const MotivationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    final quote = ref.watch(dailyQuoteProvider);

    return GlassAnimated(
      entrance: GlassEntrance.fade,
      child: Semantics(
        label: 'Quote of the day: ${quote.text}',
        child: GlassCard(
          margin: EdgeInsets.zero,
          padding: AppSpacing.lg.all,
          decoration: GlassDecoration(
            color: colors.glass,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: const GlassBorder(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.format_quote_rounded, color: colors.primary),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Quote of the day',
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                '“${quote.text}”',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                '— ${quote.author}',
                style: textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
