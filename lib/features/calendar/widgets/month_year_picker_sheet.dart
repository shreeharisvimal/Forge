// Month/year picker for the Forge application.
//
// A glass bottom sheet to jump straight to any month: a year scroller plus a
// 4x3 month grid. Returns the chosen [DateTime] (first of month) or null.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../providers/calendar_providers.dart';

/// Opens the month/year picker seeded with [current].
Future<DateTime?> showMonthYearPicker(
  BuildContext context, {
  required DateTime current,
}) {
  return GlassBottomSheet.show<DateTime>(
    context,
    initialChildSize: 0.6,
    maxChildSize: 0.7,
    builder: (context) =>
        MonthYearPickerSheet(current: current),
  );
}

/// The month/year picker sheet.
class MonthYearPickerSheet extends ConsumerStatefulWidget {
  /// Creates the picker.
  const MonthYearPickerSheet({super.key, required this.current});

  /// The currently focused month.
  final DateTime current;

  @override
  ConsumerState<MonthYearPickerSheet> createState() =>
      _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends ConsumerState<MonthYearPickerSheet> {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.current.year;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final now = ref.watch(calendarNowProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Jump to month',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: colors.onSurface),
              ),
              const Spacer(),
              GlassIconButton(
                icon: Icons.chevron_left_rounded,
                semanticLabel: 'Previous year',
                onPressed: () => setState(() => _year -= 1),
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                '$_year',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(width: AppSpacing.sm),
              GlassIconButton(
                icon: Icons.chevron_right_rounded,
                semanticLabel: 'Next year',
                onPressed: () => setState(() => _year += 1),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var month = 1; month <= 12; month++)
                SizedBox(
                  width: (MediaQuery.sizeOf(context).width - AppSpacing.lg * 4) / 3,
                  child: GlassChip(
                    label: _months[month - 1],
                    selected: month == widget.current.month && _year == widget.current.year,
                    onTap: () => Navigator.of(context).pop(
                      DateTime(_year, month),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          GlassButton(
            label: 'Today',
            icon: Icons.today_rounded,
            variant: GlassButtonVariant.ghost,
            expanded: true,
            onPressed: () => Navigator.of(context).pop(
              DateTime(now.year, now.month),
            ),
          ),
        ],
      ),
    );
  }
}
