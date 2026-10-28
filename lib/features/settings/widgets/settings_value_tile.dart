// Settings value tile for the Forge application.
//
// A settings row whose trailing shows the current value and opens a glass
// bottom-sheet picker when tapped. Reuses [GlassDropdownOption] so options
// read the same everywhere.
library;

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';

/// A settings row that opens a picker sheet.
class SettingsValueTile<T> extends StatelessWidget {
  /// Creates a settings value tile.
  const SettingsValueTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.valueLabel,
    this.searchable = false,
  });

  /// The row title.
  final String title;

  /// Optional supporting text.
  final String? subtitle;

  /// Optional leading icon shown in the picker header.
  final IconData? icon;

  /// The currently selected option.
  final T value;

  /// The selectable options.
  final List<GlassDropdownOption<T>> options;

  /// Invoked when a new value is selected.
  final ValueChanged<T> onChanged;

  /// The formatted label of the current value.
  final String valueLabel;

  /// Whether the picker includes a search bar.
  final bool searchable;

  GlassDropdownOption<T>? get _selected {
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    await HapticHelper.selection();
    if (!context.mounted) return;
    final result = await GlassBottomSheet.show<T>(
      context,
      showDragHandle: true,
      builder: (context) => _SettingsPickerSheet<T>(
        title: title,
        icon: icon,
        options: options,
        selected: value,
        searchable: searchable,
      ),
    );
    if (!context.mounted) return;
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final selected = _selected;

    return GlassListTile(
      title: title,
      subtitle: subtitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            valueLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.chevron_right_rounded,
            size: AppIconSize.medium,
            color: colors.onSurfaceMuted,
          ),
        ],
      ),
      onTap: () => _open(context),
      semanticLabel: '$title: ${selected?.label ?? valueLabel}',
    );
  }
}

/// The option list rendered inside the value picker sheet.
class _SettingsPickerSheet<T> extends StatefulWidget {
  const _SettingsPickerSheet({
    required this.title,
    required this.icon,
    required this.options,
    required this.selected,
    required this.searchable,
  });

  final String title;
  final IconData? icon;
  final List<GlassDropdownOption<T>> options;
  final T selected;
  final bool searchable;

  @override
  State<_SettingsPickerSheet<T>> createState() => _SettingsPickerSheetState<T>();
}

class _SettingsPickerSheetState<T> extends State<_SettingsPickerSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.options
        : widget.options
            .where((option) => option.label.toLowerCase().contains(query))
            .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: AppIconSize.small, color: colors.primary),
              SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        if (widget.searchable) ...[
          SizedBox(height: AppSpacing.md),
          GlassSearchBar(
            hintText: 'Search...',
            onChanged: (value) => setState(() => _query = value),
          ),
        ],
        SizedBox(height: AppSpacing.md),
        if (filtered.isEmpty)
          Padding(
            padding: AppSpacing.xxl.all,
            child: Center(
              child: Text(
                'No options match',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
              ),
            ),
          )
        else
          for (final option in filtered) ...[
            GlassListTile(
              title: option.label,
              leading: option.icon == null
                  ? null
                  : Icon(
                      option.icon,
                      size: AppIconSize.small,
                      color: colors.onSurfaceMuted,
                    ),
              trailing: option.value == widget.selected
                  ? Icon(
                      Icons.check_rounded,
                      size: AppIconSize.small,
                      color: colors.primary,
                    )
                  : null,
              selected: option.value == widget.selected,
              dense: true,
              onTap: () => Navigator.of(context).pop(option.value),
            ),
            SizedBox(height: AppSpacing.xs),
          ],
      ],
    );
  }
}
