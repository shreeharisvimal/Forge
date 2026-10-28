// Calendar date service for the Forge application.
//
// DateService is a stateless facade over the shared date helpers in
// core/utils/dates.dart. It owns the app's notion of "today" through an
// injectable clock so that streak math, relative labels and calendar
// queries can all be unit tested against a fixed point in time. The only
// state is the clock and formatting hooks supplied at construction.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../utils/dates.dart' as date_utils;
import '../../utils/ids.dart' as ids;

/// A stateless calendar and date-formatting facade.
///
/// Every method is pure: given the same inputs (and clock) it returns the
/// same output. [today] and [relative] consult the injectable [clock] so
/// tests can pin "now" to a fixed instant.
class DateService {
  /// Creates a date service.
  ///
  /// [clock] supplies the current instant and defaults to [DateTime.now].
  /// [dateFormatter] renders [format] output, defaulting to an `intl`
  /// `MMM d, yyyy` formatter; it is the seam for future localization.
  DateService({
    DateTime Function()? clock,
    String Function(DateTime)? dateFormatter,
  }) : _clock = clock ?? DateTime.now,
       _dateFormatter = dateFormatter ?? _defaultDateFormatter;

  final DateTime Function() _clock;
  final String Function(DateTime) _dateFormatter;

  /// The `intl` pattern used by the default formatter.
  static const String _fullDatePattern = 'MMM d, yyyy';

  /// The `intl` pattern used by [formatShort].
  static const String _shortDatePattern = 'MMM d';

  /// The `intl` pattern used by [formatTime].
  static const String _timePattern = 'h:mm a';

  /// Days in a week, used for week math.
  static const int _weekLength = 7;

  /// Cells in a complete calendar grid: six weeks of seven days.
  static const int _calendarGridCells = 42;

  /// Days in the "Xd ago" bucket of [relative].
  static const int _relativeWeekDays = 7;

  /// Days in the "Xw ago" bucket of [relative] (four weeks).
  static const int _relativeMonthDays = 28;

  /// Relative labels are plain strings pending a localization layer.
  static const String _justNowLabel = 'just now';
  static const String _yesterdayLabel = 'yesterday';

  static String _defaultDateFormatter(DateTime date) =>
      DateFormat(_fullDatePattern).format(date);

  /// Today's calendar day, normalized to midnight local.
  DateTime today() => date_utils.dateOnly(_clock());

  /// Whether [date] falls on today's calendar day.
  bool isToday(DateTime date) => date_utils.isSameDay(date, today());

  /// Whether [a] and [b] fall on the same calendar day.
  bool isSameDay(DateTime a, DateTime b) => date_utils.isSameDay(a, b);

  /// Whether [day] lies within the inclusive range [from]..[to].
  ///
  /// Delegates to `isBetweenInclusive`; comparisons are day-precision.
  bool isInRange(DateTime day, DateTime from, DateTime to) =>
      date_utils.isBetweenInclusive(day, from, to);

  /// The Monday at the start of the week containing [date].
  DateTime startOfWeek(DateTime date) {
    final day = date_utils.dateOnly(date);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  /// The Sunday at the end of the week containing [date].
  DateTime endOfWeek(DateTime date) =>
      startOfWeek(date).add(const Duration(days: _weekLength - 1));

  /// The first day of the month containing [date].
  DateTime startOfMonth(DateTime date) => DateTime(date.year, date.month);

  /// The last day of the month containing [date].
  DateTime endOfMonth(DateTime date) => DateTime(date.year, date.month + 1, 0);

  /// The seven days of the week containing [date], Monday-first.
  List<DateTime> daysInWeek(DateTime date) {
    final start = startOfWeek(date);
    return List.generate(
      _weekLength,
      (index) => start.add(Duration(days: index)),
    );
  }

  /// The complete calendar grid for the month containing [date].
  ///
  /// Returns exactly 42 cells (six weeks, Monday-first) starting on the
  /// Monday on or before the first of the month. Leading and trailing cells
  /// spill into the adjacent months so the grid is always complete,
  /// regardless of which weekday the month starts on.
  List<DateTime> daysInMonth(DateTime date) {
    final start = startOfWeek(startOfMonth(date));
    return List.generate(
      _calendarGridCells,
      (index) => start.add(Duration(days: index)),
    );
  }

  /// The number of days in the calendar month containing [date].
  int daysInMonthOf(DateTime date) {
    final first = DateTime(date.year, date.month);
    final nextMonth = DateTime(date.year, date.month + 1);
    return nextMonth.difference(first).inDays;
  }

  /// Formats [date] with the configured formatter (default `MMM d, yyyy`).
  String format(DateTime date) => _dateFormatter(date);

  /// Formats [date] as `MMM d`.
  String formatShort(DateTime date) =>
      DateFormat(_shortDatePattern).format(date);

  /// Formats [date] as `h:mm a`.
  String formatTime(DateTime date) => DateFormat(_timePattern).format(date);

  /// Formats [date] as a compact, sortable ISO-8601 UTC string.
  String formatIso(DateTime date) => ids.toIsoString(date);

  /// A relative, `intl`-free label for [date] based on the clock.
  ///
  /// Buckets by elapsed time: under a minute is `just now`, under an hour
  /// is `Xm ago`, today is `Xh ago`, yesterday is `yesterday`, under a
  /// week is `Xd ago`, under four weeks is `Xw ago`, and anything older
  /// falls back to [format]. Strings are deliberately plain English
  /// pending a localization layer; using the clock keeps "today" and
  /// "yesterday" testable.
  String relative(DateTime date) {
    final now = _clock();
    final elapsed = now.difference(date);
    if (elapsed.inMinutes < 1) return _justNowLabel;
    if (elapsed.inHours < 1) return '${elapsed.inMinutes}m ago';
    if (isToday(date)) return '${elapsed.inHours}h ago';
    final yesterday = today().subtract(const Duration(days: 1));
    if (date_utils.isSameDay(date, yesterday)) return _yesterdayLabel;
    if (elapsed.inDays < _relativeWeekDays) return '${elapsed.inDays}d ago';
    if (elapsed.inDays < _relativeMonthDays) {
      return '${elapsed.inDays ~/ _relativeWeekDays}w ago';
    }
    return format(date);
  }

  /// The next [weekday] strictly after [from], Monday (1) to Sunday (7).
  ///
  /// Returns null when [weekday] falls outside the 1..7 range.
  DateTime? nextWeekday(DateTime from, int weekday) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) return null;
    final day = date_utils.dateOnly(from);
    var offset = weekday - day.weekday;
    if (offset <= 0) offset += _weekLength;
    return day.add(Duration(days: offset));
  }

  /// The 1-based row of [date] within the month's calendar grid.
  ///
  /// Week 1 is the Monday-starting week that contains the first of the
  /// month; results range 1..6 depending on the month's layout.
  int weekOfMonth(DateTime date) {
    final day = date_utils.dateOnly(date);
    final gridStart = startOfWeek(startOfMonth(date));
    return day.difference(gridStart).inDays ~/ _weekLength + 1;
  }

  /// The day of the week with Monday as 1 through Sunday as 7.
  int dayOfWeekMondayFirst(DateTime date) => date.weekday;

  /// The length of the current workout streak, or zero when inactive.
  ///
  /// Algorithm: the input dates are normalized to midnight, de-duplicated
  /// and sorted ascending. If the most recent date is today or yesterday
  /// the streak counts backward one day at a time while the sorted list
  /// stays consecutive; any gap, or a most recent date older than
  /// yesterday, yields 0. "Today" comes from the injected clock, so the
  /// result is pure and testable.
  int currentStreak(List<DateTime> dates) {
    final unique = {for (final date in dates) date_utils.dateOnly(date)}.toList()
      ..sort();
    if (unique.isEmpty) return 0;
    final mostRecent = unique.last;
    final currentDay = today();
    if (!date_utils.isSameDay(mostRecent, currentDay) &&
        !date_utils.isSameDay(
          mostRecent,
          currentDay.subtract(const Duration(days: 1)),
        )) {
      return 0;
    }
    var streak = 1;
    var cursor = mostRecent.subtract(const Duration(days: 1));
    for (var index = unique.length - 2; index >= 0; index--) {
      if (!date_utils.isSameDay(unique[index], cursor)) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

/// Provides a [DateService] using the system clock and default formatter.
final dateServiceProvider = Provider<DateService>((ref) => DateService());
