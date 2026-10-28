// Weight logging sheet for the Forge dashboard.
//
// A glass bottom sheet for a quick daily weigh-in and (optionally) the
// target body weight. Saving today's weight upserts the day's entry; the
// goal is persisted through the settings document.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../../../core/utils/dates.dart';
import '../../../models/weight_entry.dart';
import '../../../services/providers.dart';
import '../providers/dashboard_providers.dart';

/// Opens the weight logging sheet.
Future<void> showWeightLogSheet(BuildContext context) {
  return GlassBottomSheet.show(
    context,
    initialChildSize: 0.55,
    maxChildSize: 0.7,
    builder: (context) => const _WeightLogSheet(),
  );
}

class _WeightLogSheet extends ConsumerStatefulWidget {
  const _WeightLogSheet();

  @override
  ConsumerState<_WeightLogSheet> createState() => _WeightLogSheetState();
}

class _WeightLogSheetState extends ConsumerState<_WeightLogSheet> {
  late final TextEditingController _weightController;
  late final TextEditingController _goalController;
  String? _weightError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(dashboardSettingsProvider);
    final latest = ref.read(weightRepositoryProvider).latest();
    _weightController =
        TextEditingController(text: latest == null ? '' : _trim(latest.weight));
    _goalController = TextEditingController(
      text: settings.goalWeight == null ? '' : _trim(settings.goalWeight!),
    );
  }

  static String _trim(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  @override
  void dispose() {
    _weightController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _weightError = null);
    final weightText = _weightController.text.trim();
    final goalText = _goalController.text.trim();

    final weight = weightText.isEmpty ? null : double.tryParse(weightText);
    if (weightText.isNotEmpty && weight == null) {
      setState(() => _weightError = 'Enter a valid number');
      return;
    }

    setState(() => _saving = true);
    try {
      final repository = ref.read(weightRepositoryProvider);
      final today = dateOnly(DateTime.now());
      if (weight != null) {
        final existing = repository.onDate(today);
        if (existing != null) {
          await repository.save(existing.copyWith(weight: weight));
        } else {
          await repository.save(WeightEntry(date: today, weight: weight));
        }
      }
      if (goalText.isNotEmpty) {
        final goal = double.tryParse(goalText);
        if (goal != null) {
          final settings = ref.read(dashboardSettingsProvider);
          await ref
              .read(settingsRepositoryProvider)
              .replace(settings.copyWith(goalWeight: () => goal));
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    final unit = ref.watch(dashboardSettingsProvider).weightUnit;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Log your weight',
            style: textTheme.titleLarge?.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Record today’s weigh-in and set the target you are working toward.',
            style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceMuted),
          ),
          SizedBox(height: AppSpacing.xxl),
          GlassTextField(
            controller: _weightController,
            label: 'Today’s weight ($unit)',
            hintText: 'e.g. ${unit == 'kg' ? '82.4' : '181.5'}',
            prefixIcon: Icons.monitor_weight_outlined,
            errorText: _weightError,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: AppSpacing.lg),
          GlassTextField(
            controller: _goalController,
            label: 'Goal weight ($unit)',
            hintText: 'Optional',
            prefixIcon: Icons.flag_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          SizedBox(height: AppSpacing.xxl),
          GlassButton(
            label: 'Save',
            icon: Icons.check_rounded,
            expanded: true,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
          SizedBox(height: AppSpacing.sm),
          GlassButton(
            label: 'Cancel',
            variant: GlassButtonVariant.ghost,
            expanded: true,
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
