// Calendar repository for the Forge application.
//
// Persistence and queries for [CalendarDay] rows.
library;

import '../../core/utils/dates.dart';
import '../../models/calendar_day.dart';
import 'base_repository.dart';

/// Query surface for [CalendarDay] rows.
abstract class CalendarRepository extends BaseRepository<CalendarDay> {
  /// Creates a repository backed by [box].
  CalendarRepository(super.box);

  /// The row for [date] (day precision), or null.
  CalendarDay? onDate(DateTime date) {
    for (final day in all()) {
      if (isSameDay(day.date, date)) return day;
    }
    return null;
  }

  /// All rows within the inclusive day range [from]..[to], oldest first.
  List<CalendarDay> between(DateTime from, DateTime to) {
    final result = all()
        .where((day) => isBetweenInclusive(day.date, from, to))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }
}

/// Hive-backed [CalendarRepository].
class HiveCalendarRepository extends CalendarRepository {
  /// Creates a repository backed by [box].
  HiveCalendarRepository(super.box);
}
