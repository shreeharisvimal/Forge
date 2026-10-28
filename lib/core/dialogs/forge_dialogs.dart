// Forge global dialog system.
//
// Typed, reusable dialogs composed on top of [GlassDialog]. These are the
// only entry points feature code should use for confirm, delete, info,
// input, selection and progress dialogs so every modal in the app shares
// the same glass presentation, haptics and accessibility behavior.
library;

import 'package:flutter/material.dart';

import '../design/forge_design.dart';

/// One selectable option for [showForgeSelectionDialog].
class ForgeSelectionOption<T> {
  /// Creates a selection option.
  const ForgeSelectionOption({
    required this.label,
    this.value,
    this.icon,
    this.subtitle,
  });

  /// The display label.
  final String label;

  /// The value returned when this option is chosen.
  final T? value;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional supporting text.
  final String? subtitle;
}

/// Presents a confirm dialog and resolves to whether the user confirmed.
Future<bool?> showForgeConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
  IconData? icon,
}) {
  HapticHelper.selection();
  return GlassDialog.showContent<bool>(
    context,
    title: title,
    message: message,
    icon: icon != null ? Icon(icon, color: _accent(context, destructive)) : null,
    accentColor: destructive ? Theme.of(context).forgeColors.danger : null,
    actions: [
      DialogActions.cancel(context: context, label: cancelLabel),
      DialogActions.confirm(
        label: confirmLabel,
        onPressed: () =>
            Navigator.of(context, rootNavigator: true).pop(true),
      ),
    ],
  );
}

/// Presents a destructive delete confirmation.
Future<bool?> showForgeDeleteDialog(
  BuildContext context, {
  required String title,
  required String message,
  String deleteLabel = 'Delete',
  String cancelLabel = 'Cancel',
}) {
  HapticHelper.warning();
  return GlassDialog.showContent<bool>(
    context,
    title: title,
    message: message,
    icon: const Icon(Icons.delete_rounded, color: ForgeColors.danger),
    accentColor: ForgeColors.danger,
    actions: [
      DialogActions.cancel(context: context, label: cancelLabel),
      GlassButton(
        label: deleteLabel,
        variant: GlassButtonVariant.filled,
        expanded: true,
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
      ),
    ],
  );
}

/// Presents an informational dialog and resolves when it is closed.
Future<void> showForgeInfoDialog(
  BuildContext context, {
  required String title,
  String? message,
  IconData? icon,
  String okLabel = 'OK',
}) {
  return GlassDialog.showContent<void>(
    context,
    title: title,
    message: message,
    icon: icon != null ? Icon(icon, color: Theme.of(context).forgeColors.info) : null,
    accentColor: Theme.of(context).forgeColors.info,
    actions: [
      DialogActions.confirm(
        label: okLabel,
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
      ),
    ],
  );
}

/// Presents a text input dialog and resolves with the entered value.
///
/// Returns `null` when cancelled or the input fails validation.
Future<String?> showForgeInputDialog(
  BuildContext context, {
  required String title,
  String? message,
  String? hintText,
  String? initialValue,
  String confirmLabel = 'Save',
  String cancelLabel = 'Cancel',
  String? Function(String value)? validator,
  bool obscureText = false,
  TextInputType? keyboardType,
}) {
  HapticHelper.selection();
  return GlassDialog.show<String>(
    context,
    builder: (context) => _ForgeInputDialog(
      title: title,
      message: message,
      hintText: hintText,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
    ),
  );
}

/// Presents a single-choice selection dialog and resolves with the chosen
/// option's value (the [ForgeSelectionOption] itself when it has none).
Future<T?> showForgeSelectionDialog<T>(
  BuildContext context, {
  required String title,
  required List<ForgeSelectionOption<T>> options,
  T? selected,
}) {
  HapticHelper.selection();
  return GlassDialog.show<T>(
    context,
    builder: (context) => _ForgeSelectionDialog<T>(
      title: title,
      options: options,
      selected: selected,
    ),
  );
}

/// Presents a progress dialog and returns a controller to update/dismiss it.
Future<ForgeProgressDialogController> showForgeProgressDialog(
  BuildContext context, {
  required String message,
}) {
  final controller = ForgeProgressDialogController();
  GlassDialog.show<void>(
    context,
    barrierDismissible: false,
    builder: (context) {
      controller.attach(context);
      return _ForgeProgressDialog(controller: controller, message: message);
    },
  );
  return Future.value(controller);
}

/// Controls an active progress dialog created by [showForgeProgressDialog].
class ForgeProgressDialogController extends ChangeNotifier {
  String _message = '';
  double? _progress;
  BuildContext? _dialogContext;

  /// The dialog's current message.
  String get message => _message;

  /// The dialog's current progress (0–1), or `null` for indeterminate.
  double? get progress => _progress;

  /// Binds this controller to the dialog's context for dismissal.
  void attach(BuildContext context) => _dialogContext = context;

  /// Updates the message and/or progress shown by the dialog.
  void update({String? message, double? progress}) {
    _message = message ?? _message;
    _progress = progress ?? _progress;
    notifyListeners();
  }

  /// Closes the dialog.
  void dismiss() {
    final context = _dialogContext;
    if (context != null && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

Color _accent(BuildContext context, bool destructive) {
  final colors = Theme.of(context).forgeColors;
  return destructive ? colors.danger : colors.primary;
}

/// Stateful input dialog content.
class _ForgeInputDialog extends StatefulWidget {
  const _ForgeInputDialog({
    required this.title,
    this.message,
    this.hintText,
    this.initialValue,
    this.confirmLabel,
    this.cancelLabel,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
  });

  final String title;
  final String? message;
  final String? hintText;
  final String? initialValue;
  final String? confirmLabel;
  final String? cancelLabel;
  final String? Function(String value)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  State<_ForgeInputDialog> createState() => _ForgeInputDialogState();
}

class _ForgeInputDialogState extends State<_ForgeInputDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text;
    final error = widget.validator?.call(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context, rootNavigator: true).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialogContent(
      title: widget.title,
      message: widget.message,
      content: GlassTextField(
        controller: _controller,
        hintText: widget.hintText,
        errorText: _error,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: TextInputAction.done,
        autofocus: true,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        DialogActions.cancel(context: context, label: widget.cancelLabel ?? 'Cancel'),
        GlassButton(
          label: widget.confirmLabel ?? 'Save',
          expanded: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}

/// Single-choice selection dialog content.
class _ForgeSelectionDialog<T> extends StatelessWidget {
  const _ForgeSelectionDialog({
    required this.title,
    required this.options,
    this.selected,
  });

  final String title;
  final List<ForgeSelectionOption<T>> options;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return GlassDialogContent(
      title: title,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.5,
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: options.length,
          separatorBuilder: (_, _) => SizedBox(height: AppSpacing.xs),
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = option.value == selected ||
                (selected == null && option.value == null);
            return GlassListTile(
              title: option.label,
              subtitle: option.subtitle,
              leading: option.icon != null
                  ? Icon(option.icon, color: colors.primary)
                  : null,
              selected: isSelected,
              trailing: isSelected
                  ? Icon(Icons.check_rounded, color: colors.primary)
                  : null,
              onTap: () =>
                  Navigator.of(context, rootNavigator: true).pop(option.value),
            );
          },
        ),
      ),
      actions: [
        DialogActions.cancel(context: context),
      ],
    );
  }
}

/// Progress dialog content driven by a [ForgeProgressDialogController].
class _ForgeProgressDialog extends StatelessWidget {
  const _ForgeProgressDialog({
    required this.controller,
    required this.message,
  });

  final ForgeProgressDialogController controller;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final colors = Theme.of(context).forgeColors;
        final progress = controller.progress;
        return GlassDialogContent(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassLoading(variant: GlassLoadingVariant.spinner),
              SizedBox(height: AppSpacing.lg),
              Text(
                controller.message.isEmpty ? message : controller.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
              ),
              if (progress != null) ...[
                SizedBox(height: AppSpacing.lg),
                GlassProgressBar(
                  value: progress,
                  height: AppSpacing.xs,
                  color: colors.primary,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
