// Tag input widget for the exercise editor.
//
// Lets the user type free-form tags and press Enter / the add button to turn
// them into chips. Existing tags can be removed by tapping their chip.
library;

import 'package:flutter/material.dart';

import '../../../../core/design/forge_design.dart';

/// A text field that collects values into removable chips.
class TagInputField extends StatefulWidget {
  /// Creates a tag input.
  const TagInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.values,
    required this.onChanged,
    this.suggestions = const [],
  });

  /// Field label.
  final String label;

  /// Input hint text.
  final String hint;

  /// The current tags.
  final List<String> values;

  /// Called whenever the tag set changes.
  final ValueChanged<List<String>> onChanged;

  /// Optional suggestions shown as chips to quick-add.
  final List<String> suggestions;

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final tag = raw.trim();
    if (tag.isEmpty) return;
    if (widget.values.contains(tag)) {
      _controller.clear();
      return;
    }
    widget.onChanged([...widget.values, tag]);
    _controller.clear();
  }

  void _remove(String tag) {
    widget.onChanged(widget.values.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final tag in widget.values)
              GlassChip(
                label: tag,
                onDeleted: () => _remove(tag),
              ),
            if (widget.suggestions.isNotEmpty)
              ..._suggestionChips(context),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassTextField(
          controller: _controller,
          hintText: widget.hint,
          textInputAction: TextInputAction.done,
          onSubmitted: _add,
          suffixIcon: GlassIconButton(
            icon: Icons.add_circle_outline,
            variant: GlassIconButtonVariant.ghost,
            color: colors.primary,
            tooltip: 'Add tag',
            onPressed: () => _add(_controller.text),
          ),
        ),
      ],
    );
  }

  List<Widget> _suggestionChips(BuildContext context) {
    final unused = widget.suggestions
        .where((suggestion) => !widget.values.contains(suggestion))
        .toList();
    return unused
        .map(
          (suggestion) => GlassChip(
            label: '+ $suggestion',
            onTap: () => _add(suggestion),
          ),
        )
        .toList();
  }
}
