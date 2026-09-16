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
/// [includePast] includes earlier days **inside the same date window**;
/// [customRange] overrides the week.
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
  bool get hasActiveFilters => hasCustomRange || includePast;

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

  /// Monday of the ISO week that contains [day].
  static DateTime startOfWeek(DateTime day) {
    final start = dateOnly(day);
    return start.subtract(Duration(days: start.weekday - DateTime.monday));
  }

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

  /// Date window actually applied to the list.
  ///
  /// Custom range wins; otherwise this week. [CultoListFilter.includePast]
  /// only unlocks days before today inside that window — it never drops
  /// the period filter.
  static CultoDateRange effectiveRange(CultoListFilter filter, DateTime now) {
    final today = dateOnly(now);
    if (filter.customRange != null) {
      var start = dateOnly(filter.customRange!.start);
      final end = dateOnly(filter.customRange!.end);
      if (!filter.includePast && start.isBefore(today)) start = today;
      return CultoDateRange(start: start, end: end);
    }
    final start = filter.includePast ? startOfWeek(today) : today;
    return CultoDateRange(start: start, end: endOfWeek(today));
  }

  /// Earliest day the date-range picker may select.
  ///
  /// Past days stay disabled until [CultoListFilter.includePast] is on.
  static DateTime firstSelectableDate(CultoListFilter filter, DateTime now) {
    final today = dateOnly(now);
    if (filter.includePast) {
      return DateTime(today.year - 5, today.month, today.day);
    }
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
    final range = effectiveRange(filter, now);

    final matches = cultos.where((culto) {
      if (!_inRange(dateOnly(culto.date), range)) return false;
      if (query.isEmpty) return true;
      return culto.title.toLowerCase().contains(query) ||
          DateFormatters.short(culto.date).contains(query) ||
          DateFormatters.long(culto.date).toLowerCase().contains(query);
    }).toList();

    matches.sort((a, b) {
      final byDate = dateOnly(a.date).compareTo(dateOnly(b.date));
      if (byDate != 0) return byDate;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return matches;
  }

  static bool _inRange(DateTime date, CultoDateRange range) {
    final start = dateOnly(range.start);
    final end = dateOnly(range.end);
    if (end.isBefore(start)) return false;
    return !date.isBefore(start) && !date.isAfter(end);
  }
}
