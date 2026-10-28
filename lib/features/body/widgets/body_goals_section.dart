// Body goals section for the Forge application.
//
// One progress card per goal: current value, target, direction and a
// 0..1 progress bar. Tapping a card opens the goal editor; an add button
// opens it for the next field without a goal. Pure presentation over
// [BodyGoalProgress].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../../../core/overlays/forge_overlay_extensions.dart';
import '../../../models/settings_model.dart';
import '../domain/body_goals.dart';
import '../domain/body_measurement_fields.dart';
import '../domain/body_measurement_models.dart';
import '../presentation/body_formatters.dart';
import '../providers/body_providers.dart';

/// Opens the goal editor for [field].
Future<void> showBodyGoalEditorSheet(
  BuildContext context, {
  required BodyField field,
  BodyGoal? existing,
}) {
  return GlassBottomSheet.show(
    context,
    maxChildSize: 0.7,
    builder: (context) =>
        BodyGoalEditorSheet(field: field, existing: existing),
  );
}

/// The goal progress cards.
class BodyGoalsSection extends ConsumerWidget {
  /// Creates the goals section.
  const BodyGoalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(bodySnapshotProvider).goals;
    final settings = ref.watch(bodySettingsProvider);

    final cards = <Widget>[
      for (final progress in goals)
        _GoalCard(
          progress: progress,
          settings: settings,
          onTap: () => showBodyGoalEditorSheet(
            context,
            field: progress.goal.field,
            existing: progress.goal,
          ),
        ),
    ];

    final remaining = BodyField.all
        .where((field) => goals.every((goal) => goal.goal.field != field))
        .toList();
    if (remaining.isNotEmpty) {
      cards.add(
        _AddGoalCard(
          fields: remaining,
          onAdd: (field) => showBodyGoalEditorSheet(context, field: field),
        ),
      );
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.flag_outlined,
              size: AppIconSize.small,
              color: Theme.of(context).forgeColors.secondary,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              'Goals',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Theme.of(context).forgeColors.onSurface),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: cards,
        ),
      ],
    );
  }
}

/// A single goal progress card.
class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.progress,
    required this.settings,
    required this.onTap,
  });

  final BodyGoalProgress progress;
  final SettingsModel settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final goal = progress.goal;
    final field = goal.field;
    final colors = Theme.of(context).forgeColors;
    final current = progress.current;
    final ratio = progress.progress;

    final progressValue = ratio?.clamp(0.0, 1.0) ?? 0.0;
    final met = progress.isMet;

    final subtitle = current == null
        ? 'Set a target for ${field.label.toLowerCase()}'
        : met
            ? 'Target reached'
            : '${BodyFormatters.valueWithUnit(current, field, settings)} → '
                '${BodyFormatters.valueWithUnit(goal.target, field, settings)}';

    return SizedBox(
      width: 260,
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: AppSpacing.lg.all,
        decoration: GlassDecoration(
          color: colors.glass,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: const GlassBorder(),
        ),
        child: GlassPressable(
          onTap: onTap,
          haptic: HapticType.selection,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      field.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: colors.onSurfaceMuted),
                    ),
                  ),
                  Icon(
                    met
                        ? Icons.check_circle_rounded
                        : Icons.flag_outlined,
                    size: AppIconSize.small,
                    color: met ? colors.success : colors.secondary,
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                BodyFormatters.valueWithUnit(goal.target, field, settings),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.onSurfaceMuted),
              ),
              SizedBox(height: AppSpacing.md),
              GlassProgressBar(
                value: progressValue,
                color: met ? colors.success : colors.primary,
                height: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tile that creates a goal for a field without one.
class _AddGoalCard extends StatelessWidget {
  const _AddGoalCard({required this.fields, required this.onAdd});

  final List<BodyField> fields;
  final ValueChanged<BodyField> onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return SizedBox(
      width: 260,
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: AppSpacing.lg.all,
        decoration: GlassDecoration(
          color: colors.glass,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: GlassBorder(color: colors.borderStrong, width: AppBorderWidth.hairline),
        ),
        child: GlassPressable(
          onTap: () {
            if (fields.length == 1) {
              onAdd(fields.first);
            } else {
              _showFieldPicker(context);
            }
          },
          haptic: HapticType.selection,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.add_rounded,
                color: colors.secondary,
                size: AppIconSize.medium,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Add goal',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: colors.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFieldPicker(BuildContext context) async {
    final colors = Theme.of(context).forgeColors;
    final selected = await GlassBottomSheet.show<BodyField>(
      context,
      maxChildSize: 0.7,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New goal',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final field in fields)
                  GlassChip(
                    label: field.label,
                    onTap: () => Navigator.of(context).pop(field),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    if (selected != null && context.mounted) onAdd(selected);
  }
}

/// The goal create/edit sheet.
class BodyGoalEditorSheet extends ConsumerStatefulWidget {
  /// Creates the editor sheet.
  const BodyGoalEditorSheet({super.key, required this.field, this.existing});

  /// The field the goal targets.
  final BodyField field;

  /// The stored goal being edited, or null when creating.
  final BodyGoal? existing;

  @override
  ConsumerState<BodyGoalEditorSheet> createState() => _BodyGoalEditorSheetState();
}

class _BodyGoalEditorSheetState extends ConsumerState<BodyGoalEditorSheet> {
  late final TextEditingController _targetController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final target = widget.existing?.target;
    _targetController = TextEditingController(
      text: target == null
          ? ''
          : (target == target.roundToDouble()
              ? target.toStringAsFixed(0)
              : target.toString()),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final target = double.tryParse(_targetController.text.trim());
    if (target == null || target <= 0) return;
    final editor = ref.read(bodyGoalEditorProvider);
    setState(() => _saving = true);
    await editor.set(
      field: widget.field,
      target: target,
      createdAt: widget.existing?.createdAt,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    final editor = ref.read(bodyGoalEditorProvider);
    await editor.remove(widget.field);
    if (!mounted) return;
    context.showToast('Goal removed');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(bodySettingsProvider);
    final colors = Theme.of(context).forgeColors;
    final field = widget.field;
    final unit = BodyFormatters.unitFor(field, settings);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.label,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: colors.onSurface),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      widget.existing == null ? 'New goal' : 'Edit goal',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: colors.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
              GlassIconButton(
                icon: Icons.close_rounded,
                variant: GlassIconButtonVariant.ghost,
                semanticLabel: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            field.prefersReduction ? 'Aim for' : 'Build toward',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: colors.onSurfaceMuted),
          ),
          SizedBox(height: AppSpacing.sm),
          GlassTextField(
            controller: _targetController,
            label: 'Target ($unit)',
            hintText: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Save goal',
                  icon: Icons.check_rounded,
                  onPressed: _saving ? null : _save,
                  loading: _saving,
                ),
              ),
            ],
          ),
          if (widget.existing != null) ...[
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    label: 'Remove goal',
                    icon: Icons.delete_outline_rounded,
                    variant: GlassButtonVariant.outlined,
                    onPressed: _saving ? null : _remove,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
