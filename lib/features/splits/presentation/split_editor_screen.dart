// Split editor screen for the Forge application.
//
// Creates or edits a [WorkoutSplit]: name, description, accent color, icon
// and the ordered list of days. Tapping a day opens the day editor where its
// exercises are arranged. Days can be added, renamed and reordered here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../../../core/overlays/forge_overlay_extensions.dart';
import '../../../models/workout_split.dart';
import '../../../models/workout_split_day.dart';
import '../../../services/providers.dart';
import '../split_options.dart';
import 'split_day_editor_screen.dart';

/// Creates or edits a [WorkoutSplit].
class SplitEditorScreen extends ConsumerStatefulWidget {
  /// Creates the editor, pre-filled from [split] when editing.
  const SplitEditorScreen({super.key, this.split});

  /// The split being edited, or null to create a new one.
  final WorkoutSplit? split;

  @override
  ConsumerState<SplitEditorScreen> createState() => _SplitEditorScreenState();
}

class _SplitEditorScreenState extends ConsumerState<SplitEditorScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late List<WorkoutSplitDay> _days;
  late int _color;
  late int _iconCodePoint;
  late bool _isActive;

  bool get _isEditing => widget.split != null;

  @override
  void initState() {
    super.initState();
    final split = widget.split;
    _nameController.text = split?.name ?? '';
    _descriptionController.text = split?.description ?? '';
    _days = [...?split?.days];
    _color = split?.color ?? kSplitColorFallback().toARGB32();
    _iconCodePoint = split?.iconCodePoint ?? kSplitIcons.first.codePoint;
    _isActive = split?.isActive ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      context.showToast('Name is required.');
      return;
    }

    final repository = ref.read(workoutSplitRepositoryProvider);
    final existing = widget.split;
    if (existing == null && _isActive) {
      // Only one split may be active; deactivate the others.
      await repository.deactivateAll();
    }

    await repository.save(
      WorkoutSplit(
        id: existing?.id,
        name: name,
        description: _descriptionController.text.trim(),
        color: _color,
        iconCodePoint: _iconCodePoint,
        isActive: _isActive,
        days: _days,
        createdAt: existing?.createdAt,
        updatedAt: existing?.updatedAt,
      ),
    );

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _addDay() async {
    final index = _days.length + 1;
    final day = await Navigator.of(context).push<WorkoutSplitDay>(
      MaterialPageRoute(
        builder: (_) => SplitDayEditorScreen(
          day: WorkoutSplitDay(name: 'Day $index'),
        ),
      ),
    );
    if (day != null) {
      setState(() => _days.add(day));
    }
  }

  Future<void> _editDay(int index) async {
    final edited = await Navigator.of(context).push<WorkoutSplitDay>(
      MaterialPageRoute(
        builder: (_) => SplitDayEditorScreen(day: _days[index]),
      ),
    );
    if (edited != null) {
      setState(() => _days[index] = edited);
    }
  }

  void _removeDay(int index) {
    setState(() => _days.removeAt(index));
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final day = _days.removeAt(oldIndex);
      _days.insert(newIndex, day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Scaffold(
      body: Column(
        children: [
          GlassAppBar(
            title: _isEditing ? 'Edit Split' : 'New Split',
            actions: [
              GlassButton(
                label: 'Save',
                size: GlassButtonSize.small,
                onPressed: _save,
              ),
            ],
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  GlassTextField(
                    controller: _nameController,
                    label: 'Name',
                    hintText: 'e.g. Push / Pull / Legs',
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GlassTextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    label: 'Description (optional)',
                    hintText: 'What this split emphasizes…',
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _AppearancePicker(
                    color: _color,
                    iconCodePoint: _iconCodePoint,
                    onColorChanged: (color) => setState(() => _color = color),
                    onIconChanged: (codePoint) =>
                        setState(() => _iconCodePoint = codePoint),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ToggleRow(
                    title: 'Set as active split',
                    subtitle: 'Used by the dashboard and schedule',
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GlassDivider(),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Days',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      GlassButton(
                        label: 'Add Day',
                        icon: Icons.add,
                        variant: GlassButtonVariant.ghost,
                        size: GlassButtonSize.small,
                        onPressed: _addDay,
                      ),
                    ],
                  ),
                  if (_days.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Text(
                        'No days yet. Add your first training day.',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceMuted,
                                ),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _days.length,
                      onReorder: _reorder,
                      buildDefaultDragHandles: false,
                      itemBuilder: (context, index) {
                        final day = _days[index];
                        return _DayTile(
                          key: ValueKey(day.id),
                          day: day,
                          index: index,
                          onTap: () => _editDay(index),
                          onRemove: () => _removeDay(index),
                        );
                      },
                    ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Color + icon selection for the split.
class _AppearancePicker extends StatelessWidget {
  const _AppearancePicker({
    required this.color,
    required this.iconCodePoint,
    required this.onColorChanged,
    required this.onIconChanged,
  });

  final int color;
  final int iconCodePoint;
  final ValueChanged<int> onColorChanged;
  final ValueChanged<int> onIconChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appearance',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final swatch in kSplitColors)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: GlassPressable(
                  onTap: () => onColorChanged(swatch.toARGB32()),
                  semanticLabel: 'Accent color',
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  child: GlassContainer(
                    width: 28,
                    height: 28,
                    decoration: GlassDecoration(
                      color: swatch,
                      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                      border: GlassBorder(
                        color: color == swatch.toARGB32()
                            ? colors.onSurface
                            : ForgeColors.border,
                        width: color == swatch.toARGB32()
                            ? AppBorderWidth.thick
                            : AppBorderWidth.thin,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final icon in kSplitIcons)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: GlassPressable(
                  onTap: () => onIconChanged(icon.codePoint),
                  semanticLabel: 'Split icon',
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    decoration: GlassDecoration(
                      color: iconCodePoint == icon.codePoint
                          ? colors.primary.withValues(alpha: 0.25)
                          : colors.glassStrong,
                      borderRadius: BorderRadius.circular(AppRadius.small),
                      border: const GlassBorder(
                        color: ForgeColors.border,
                        width: AppBorderWidth.thin,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: iconCodePoint == icon.codePoint
                          ? colors.primary
                          : colors.onSurfaceMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A single day row with drag-to-reorder handle.
class _DayTile extends StatelessWidget {
  const _DayTile({
    super.key,
    required this.day,
    required this.index,
    required this.onTap,
    required this.onRemove,
  });

  final WorkoutSplitDay day;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final subtitle = day.isRestDay
        ? 'Rest day'
        : '${day.exercises.length} exercises'
            '${day.focus.trim().isEmpty ? '' : ' · ${day.focus}'}';
    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Row(
        children: [
          GlassContainer(
            width: AppSpacing.huge,
            height: AppSpacing.huge,
            margin: const EdgeInsets.only(left: AppSpacing.lg),
            borderRadius: BorderRadius.circular(AppRadius.large),
            decoration: GlassDecoration(
              color: colors.glassStrong,
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceMuted,
                      ),
                ),
              ],
            ),
          ),
          GlassIconButton(
            icon: Icons.delete_outline,
            variant: GlassIconButtonVariant.ghost,
            color: colors.danger,
            semanticLabel: 'Remove day',
            onPressed: onRemove,
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_handle,
                color: colors.onSurfaceTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A labeled row with a [GlassSwitch].
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        GlassSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}
