// Date search sheet for the Forge application.
//
// A glass bottom sheet that searches every day with recorded content and
// returns the chosen [DateTime] (or null).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../../../core/utils/dates.dart';
import '../../dashboard/widgets/dashboard_formatters.dart';
import '../domain/calendar_queries.dart';
import '../providers/calendar_providers.dart';

/// Opens the date search sheet.
Future<DateTime?> showDateSearchSheet(BuildContext context) {
  return GlassBottomSheet.show<DateTime>(
    context,
    initialChildSize: 0.7,
    maxChildSize: 0.85,
    builder: (context) => const DateSearchSheet(),
  );
}

/// The date search sheet.
class DateSearchSheet extends ConsumerStatefulWidget {
  /// Creates the search sheet.
  const DateSearchSheet({super.key});

  @override
  ConsumerState<DateSearchSheet> createState() => _DateSearchSheetState();
}

class _DateSearchSheetState extends ConsumerState<DateSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<DateTime> _matches(List<DateTime> days) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return days.take(60).toList();
    return days
        .where((day) =>
            formatFullDayLabel(day).toLowerCase().contains(query) ||
            _isoKey(day).contains(query))
        .take(60)
        .toList();
  }

  static String _isoKey(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final days = ref.watch(calendarLoggedDaysProvider);
    final matches = _matches(days);
    final now = ref.watch(calendarNowProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Find a day',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Search by date, e.g. "Feb 2026" or "2026-02-03".',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.onSurfaceMuted),
          ),
          SizedBox(height: AppSpacing.md),
          GlassSearchBar(
            controller: _controller,
            hintText: 'Search dates…',
            onChanged: (value) => setState(() => _query = value),
          ),
          SizedBox(height: AppSpacing.md),
          if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: AppIconSize.tripleExtraLarge,
                    color: colors.onSurfaceMuted,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    days.isEmpty
                        ? 'No days logged yet. Tap a day on the calendar to start.'
                        : 'No matches for "$_query".',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: colors.onSurfaceMuted),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 340,
              child: ListView.separated(
                itemCount: matches.length,
                separatorBuilder: (_, _) => SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final day = matches[index];
                  final isToday = isSameDay(day, now);
                  return GlassListTile(
                    title: formatFullDayLabel(day),
                    subtitle: relativeDay(day, now),
                    leading: Icon(
                      isToday
                          ? Icons.today_rounded
                          : Icons.calendar_today_outlined,
                      color: isToday ? colors.primary : colors.onSurfaceMuted,
                    ),
                    onTap: () => Navigator.of(context).pop(day),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
