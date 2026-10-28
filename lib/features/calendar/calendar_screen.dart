// Calendar feature screen for the Forge application.
//
// The training calendar tab: a glass month / two-week / week grid backed by
// the calendar read model, a header with month picker, date search and jump
// to today, and a tappable summary card for the selected day. Day taps open
// the autosaving day-detail sheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart' hide isSameDay;

import '../../core/design/forge_design.dart';
import '../../core/utils/dates.dart';
import 'domain/calendar_models.dart';
import 'domain/calendar_queries.dart';
import 'providers/calendar_providers.dart';
import 'widgets/calendar_marker_badges.dart';
import 'widgets/date_search_sheet.dart';
import 'widgets/day_detail_sheet.dart';
import 'widgets/month_year_picker_sheet.dart';
import 'widgets/selected_day_summary_card.dart';



/// Calendar screen — the training month/week grid tab.
class CalendarScreen extends ConsumerStatefulWidget {
  /// Creates the calendar screen.
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  static final DateTime _firstDay = DateTime(2000, 1, 1);
  static final DateTime _lastDay = DateTime(2100, 12, 31);

  void _onDaySelected(DateTime day, DateTime focused) {
    final normalized = dateOnly(day);
    ref.read(calendarSelectedDayProvider.notifier).state = normalized;
    showDayDetailSheet(context, day: normalized);
  }

  void _onPageChanged(DateTime focused) {
    ref.read(calendarFocusedDayProvider.notifier).state = dateOnly(focused);
  }

  void _onFormatChanged(CalendarFormat format) {
    ref.read(calendarFormatProvider.notifier).state = format;
  }

  Future<void> _openMonthPicker() async {
    final picked = await showMonthYearPicker(
      context,
      current: ref.read(calendarFocusedDayProvider),
    );
    if (picked == null || !mounted) return;
    ref.read(calendarFocusedDayProvider.notifier).state = dateOnly(picked);
  }

  Future<void> _openDateSearch() async {
    final picked = await showDateSearchSheet(context);
    if (picked == null || !mounted) return;
    final normalized = dateOnly(picked);
    ref.read(calendarFocusedDayProvider.notifier).state = normalized;
    ref.read(calendarSelectedDayProvider.notifier).state = normalized;
  }

  void _jumpToToday() {
    final today = dateOnly(ref.read(calendarNowProvider));
    ref.read(calendarFocusedDayProvider.notifier).state = today;
    ref.read(calendarSelectedDayProvider.notifier).state = today;
  }

  @override
  Widget build(BuildContext context) {
    final focusedDay = ref.watch(calendarFocusedDayProvider);
    final selectedDay = ref.watch(calendarSelectedDayProvider);
    final format = ref.watch(calendarFormatProvider);
    final model = ref.watch(calendarReadModelProvider);
    final today = dateOnly(ref.watch(calendarNowProvider));
    final colors = Theme.of(context).forgeColors;

    final isCurrentMonth =
        focusedDay.year == today.year && focusedDay.month == today.month;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CalendarHeader(
              focusedDay: focusedDay,
              onMonthPicker: _openMonthPicker,
              onSearch: _openDateSearch,
              onToday: _jumpToToday,
              onFormatChanged: _onFormatChanged,
              format: format,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GlassContainer(
                decoration: GlassDecoration(
                  color: colors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: const GlassBorder(),
                ),
                borderRadius: BorderRadius.circular(AppRadius.large),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: TableCalendar<CalendarDayView>(
                  key: ValueKey(format),
                  firstDay: _firstDay,
                  lastDay: _lastDay,
                  focusedDay: focusedDay,
                  currentDay: today,
                  locale: 'en_US',
                  availableGestures: AvailableGestures.all,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerVisible: false,
                  calendarFormat: format,
                  onDaySelected: _onDaySelected,
                  onDayLongPressed: _onDaySelected,
                  onPageChanged: _onPageChanged,
                  onFormatChanged: _onFormatChanged,
                  selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                  calendarBuilders: CalendarBuilders(
                    prioritizedBuilder: (context, day, focused) {
                      final dayView = model.viewFor(day);
                      final markers = dayView?.markers ?? const <CalendarDayMarker>[];
                      return GlassCalendarCell(
                        day: day,
                        isOutside: day.month != focused.month,
                        isSelected: isSameDay(day, selectedDay),
                        isToday: isSameDay(day, today),
                        isPast: day.isBefore(today),
                        isFuture: day.isAfter(today),
                        heroTag:
                            'calendar-day-summary-${day.year}-${day.month}-${day.day}',
                        markers: markers.isNotEmpty
                            ? [CalendarMarkerBadges(markers: markers, limit: 3)]
                            : const [],
                      );
                    },

                  ),
                  calendarStyle: const CalendarStyle(
                    outsideDaysVisible: true,
                    isTodayHighlighted: true,
                    cellMargin: EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 2,
                    ),
                  ),
                  daysOfWeekHeight: AppSpacing.giant,
                ),
              ),
            ),
            if (!isCurrentMonth)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GlassChip(
                    label: 'Back to today',
                    icon: Icons.today_rounded,
                    onTap: _jumpToToday,
                  ),
                ),
              ),
            SizedBox(height: AppSpacing.sm),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SelectedDaySummaryCard(day: selectedDay),
                    SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The calendar header: title, actions and format control.
class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.focusedDay,
    required this.format,
    required this.onMonthPicker,
    required this.onSearch,
    required this.onToday,
    required this.onFormatChanged,
  });

  final DateTime focusedDay;
  final CalendarFormat format;
  final VoidCallback onMonthPicker;
  final VoidCallback onSearch;
  final VoidCallback onToday;
  final ValueChanged<CalendarFormat> onFormatChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatMonthTitle(focusedDay),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              GlassIconButton(
                icon: Icons.search_rounded,
                tooltip: 'Find a day',
                semanticLabel: 'Find a day',
                onPressed: onSearch,
              ),
              SizedBox(width: AppSpacing.xs),
              GlassIconButton(
                icon: Icons.calendar_month_rounded,
                tooltip: 'Jump to month',
                semanticLabel: 'Jump to month',
                onPressed: onMonthPicker,
              ),
              SizedBox(width: AppSpacing.xs),
              GlassIconButton(
                icon: Icons.today_rounded,
                tooltip: 'Today',
                semanticLabel: 'Today',
                onPressed: onToday,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          GlassSegmentedControl(
            options: const ['Month', '2 weeks', 'Week'],
            selectedIndex: format.index,
            semanticLabels: const ['Month view', 'Two week view', 'Week view'],
            onChanged: (index) =>
                onFormatChanged(CalendarFormat.values[index]),
          ),
        ],
      ),
    );
  }
}
