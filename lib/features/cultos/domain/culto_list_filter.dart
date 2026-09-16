import 'package:equatable/equatable.dart';

import '../../../core/utils/date_formatters.dart';
import 'entities/culto.dart';

/// Inclusive calendar-day interval used by the cultos list date filter.
class CultoDateRange extends Equatable {
  const CultoDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  List<Object?> get props => [start, end];
}

/// Search + date constraints on the public cultos list.
///
/// By default the list only shows remaining services in the current week
/// (today through Sunday). Past days disappear the day after they occur.
/// [includePast] opens the archive; [customRange] overrides the week window.
class CultoListFilter extends Equatable {
  const CultoListFilter({
    this.query = '',
    this.customRange,
    this.includePast = false,
  });

  final String query;
  final CultoDateRange? customRange;
  final bool includePast;

  bool get hasQuery => query.trim().isNotEmpty;
  bool get hasCustomRange => customRange != null;

  CultoListFilter copyWith({
    String? query,
    Object? customRange = _unset,
    bool? includePast,
  }) {
    return CultoListFilter(
      query: query ?? this.query,
      customRange: identical(customRange, _unset)
          ? this.customRange
          : customRange as CultoDateRange?,
      includePast: includePast ?? this.includePast,
    );
  }

  @override
  List<Object?> get props => [query, customRange, includePast];
}

const _unset = Object();

/// Pure date-window + search matching for [filteredCultosProvider].
abstract final class CultoListFiltering {
  /// Calendar day with time stripped, using the date's year/month/day so
  /// UTC Postgres `date` values compare cleanly with local "today".
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Last day of the ISO week (Sunday) that contains [day].
  static DateTime endOfWeek(DateTime day) {
    final start = dateOnly(day);
    return start.add(Duration(days: DateTime.sunday - start.weekday));
  }

  /// Remaining services this week: today through Sunday.
  static CultoDateRange defaultRange(DateTime now) {
    final today = dateOnly(now);
    return CultoDateRange(start: today, end: endOfWeek(today));
  }

  /// Earliest day the date-range picker may select.
  ///
  /// Past days stay disabled until [CultoListFilter.includePast] is on.
  static DateTime firstSelectableDate(CultoListFilter filter, DateTime now) {
    final today = dateOnly(now);
    if (filter.includePast) return DateTime(today.year - 5);
    return today;
  }

  static DateTime lastSelectableDate(DateTime now) {
    final today = dateOnly(now);
    return DateTime(today.year + 3, 12, 31);
  }

  /// Drops a custom range that would sit entirely in the past once the
  /// archive toggle is turned off; otherwise clamps its start to today.
  static CultoDateRange? constrainRangeToUpcoming(
    CultoDateRange? range,
    DateTime now,
  ) {
    if (range == null) return null;
    final today = dateOnly(now);
    final start = dateOnly(range.start);
    final end = dateOnly(range.end);
    if (end.isBefore(today)) return null;
    if (start.isBefore(today)) return CultoDateRange(start: today, end: end);
    return CultoDateRange(start: start, end: end);
  }

  static List<Culto> apply({
    required List<Culto> cultos,
    required CultoListFilter filter,
    required DateTime now,
  }) {
    final query = filter.query.trim().toLowerCase();
    final today = dateOnly(now);
    final weekEnd = endOfWeek(today);
    final custom = filter.customRange == null
        ? null
        : CultoDateRange(
            start: dateOnly(filter.customRange!.start),
            end: dateOnly(filter.customRange!.end),
          );

    final matches = cultos.where((culto) {
      if (!_matchesDate(
        date: dateOnly(culto.date),
        today: today,
        weekEnd: weekEnd,
        custom: custom,
        includePast: filter.includePast,
      )) {
        return false;
      }
      if (query.isEmpty) return true;
      return culto.title.toLowerCase().contains(query) ||
          DateFormatters.short(culto.date).contains(query) ||
          DateFormatters.long(culto.date).toLowerCase().contains(query);
    }).toList();

    matches.sort((a, b) {
      final byDate = dateOnly(a.date).compareTo(dateOnly(b.date));
      if (byDate != 0) {
        // Archive of every culto: most recent first. Week / range: soonest first.
        if (filter.includePast && custom == null) return -byDate;
        return byDate;
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return matches;
  }

  static bool _matchesDate({
    required DateTime date,
    required DateTime today,
    required DateTime weekEnd,
    required CultoDateRange? custom,
    required bool includePast,
  }) {
    if (custom != null) {
      if (date.isBefore(custom.start) || date.isAfter(custom.end)) return false;
      if (!includePast && date.isBefore(today)) return false;
      return true;
    }
    if (includePast) return true;
    if (date.isBefore(today) || date.isAfter(weekEnd)) return false;
    return true;
  }
}
