// Glass dropdown for the Forge Design System.
//
// A tappable glass field that opens a searchable glass bottom sheet picker
// instead of a default Material dropdown.
library;

import 'package:flutter/material.dart';

import '../colors/forge_colors.dart';
import '../extensions/theme_extensions.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../tokens/icon_size_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../utilities/haptic_helper.dart';
import 'glass_bottom_sheet.dart';
import 'glass_container.dart';
import 'glass_list_tile.dart';
import 'glass_pressable.dart';
import 'glass_search_bar.dart';

/// A single selectable option for [GlassDropdown].
class GlassDropdownOption<T> {
  /// Creates a dropdown option.
  const GlassDropdownOption({required this.label, required this.value, this.icon});

  /// Display label.
  final String label;

  /// The underlying value.
  final T value;

  /// Optional leading icon.
  final IconData? icon;
}

/// A glass dropdown field.
class GlassDropdown<T> extends StatelessWidget {
  /// Creates a glass dropdown.
  const GlassDropdown({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.searchable = false,
    this.enabled = true,
    this.semanticLabel,
  });

  /// The selectable options.
  final List<GlassDropdownOption<T>> options;

  /// The currently selected value.
  final T value;

  /// Invoked when a new value is selected.
  final ValueChanged<T> onChanged;

  /// Label rendered above the field.
  final String? label;

  /// Hint shown when no option matches the value.
  final String? hint;

  /// Whether the picker includes a search bar.
  final bool searchable;

  /// Whether the field is interactive.
  final bool enabled;

  /// Optional semantic label.
  final String? semanticLabel;

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
      builder: (context) => _GlassDropdownSheet<T>(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              label!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
            ),
          ),
        ],
        GlassPressable(
          onTap: enabled ? () => _open(context) : null,
          semanticLabel: semanticLabel ?? selected?.label,
          haptic: HapticType.selection,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: GlassContainer(
            decoration: GlassDecoration(
              color: colors.glass,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: const GlassBorder(color: ForgeColors.border),
            ),
            borderRadius: BorderRadius.circular(AppRadius.medium),
            height: AppSpacing.giant,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                if (selected?.icon != null) ...[
                  Icon(
                    selected!.icon,
                    size: AppIconSize.small,
                    color: colors.onSurfaceMuted,
                  ),
                  SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Text(
                    selected?.label ?? hint ?? 'Select...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: selected != null
                              ? colors.onSurface
                              : colors.onSurfaceMuted,
                        ),
                  ),
                ),
                Icon(
                  Icons.expand_more_rounded,
                  size: AppIconSize.medium,
                  color: colors.onSurfaceMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The option list rendered inside the picker sheet.
class _GlassDropdownSheet<T> extends StatefulWidget {
  const _GlassDropdownSheet({
    required this.options,
    required this.selected,
    required this.searchable,
  });

  final List<GlassDropdownOption<T>> options;
  final T selected;
  final bool searchable;

  @override
  State<_GlassDropdownSheet<T>> createState() => _GlassDropdownSheetState<T>();
}

class _GlassDropdownSheetState<T> extends State<_GlassDropdownSheet<T>> {
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
        Text(
          'Select',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
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
            padding: const EdgeInsets.all(AppSpacing.xxl),
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
                  : Icon(option.icon, size: AppIconSize.small, color: colors.onSurfaceMuted),
              trailing: option.value == widget.selected
                  ? Icon(Icons.check_rounded, size: AppIconSize.small, color: colors.primary)
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
