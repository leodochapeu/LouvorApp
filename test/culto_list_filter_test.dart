import 'package:flutter_test/flutter_test.dart';
import 'package:louvor_app/features/cultos/domain/culto_list_filter.dart';
import 'package:louvor_app/features/cultos/domain/entities/culto.dart';

void main() {
  // Wednesday — remaining week is 16/09 through Sunday 20/09.
  final now = DateTime(2026, 9, 16);

  Culto culto(String id, DateTime date, {String? title}) {
    return Culto(
      id: id,
      title: title ?? id,
      date: date,
      songIds: const [],
      slug: id,
      createdAt: date,
      updatedAt: date,
    );
  }

  List<Culto> apply(
    List<Culto> cultos, {
    CultoListFilter filter = const CultoListFilter(),
  }) {
    return CultoListFiltering.apply(cultos: cultos, filter: filter, now: now);
  }

  final yesterday = culto('ontem', DateTime(2026, 9, 15));
  final today = culto('hoje', DateTime(2026, 9, 16));
  final sunday = culto('domingo', DateTime(2026, 9, 20));
  final nextMonday = culto('proxima', DateTime(2026, 9, 21));

  test('default week hides cultos after their day has passed', () {
    final visible = apply([yesterday, today, sunday, nextMonday]);
    expect(visible.map((c) => c.id), ['hoje', 'domingo']);
  });

  test('on Sunday the default window is only that day', () {
    expect(
      CultoListFiltering.defaultRange(DateTime(2026, 9, 20)),
      CultoDateRange(start: DateTime(2026, 9, 20), end: DateTime(2026, 9, 20)),
    );
  });

  test('a UTC Postgres date still matches the local calendar day', () {
    final utcToday = culto('utc', DateTime.utc(2026, 9, 16));
    expect(apply([utcToday]).map((c) => c.id), ['utc']);
  });

  test('includePast without a range shows the full archive', () {
    final visible = apply(
      [yesterday, today, sunday, nextMonday],
      filter: const CultoListFilter(includePast: true),
    );
    expect(visible.map((c) => c.id), ['proxima', 'domingo', 'hoje', 'ontem']);
  });

  test('a custom range overrides the current week', () {
    final visible = apply(
      [yesterday, today, sunday, nextMonday],
      filter: CultoListFilter(
        customRange: CultoDateRange(
          start: DateTime(2026, 9, 21),
          end: DateTime(2026, 9, 27),
        ),
      ),
    );
    expect(visible.map((c) => c.id), ['proxima']);
  });

  test('past days in a custom range stay hidden until includePast is on', () {
    final range = CultoDateRange(
      start: DateTime(2026, 9, 14),
      end: DateTime(2026, 9, 16),
    );
    expect(
      apply(
        [yesterday, today],
        filter: CultoListFilter(customRange: range),
      ).map((c) => c.id),
      ['hoje'],
    );
    expect(
      apply(
        [yesterday, today],
        filter: CultoListFilter(customRange: range, includePast: true),
      ).map((c) => c.id),
      ['ontem', 'hoje'],
    );
  });

  test('search still matches title or formatted date inside the window', () {
    final family = culto('fam', DateTime(2026, 9, 20), title: 'Culto da Família');
    expect(
      apply(
        [family, today],
        filter: const CultoListFilter(query: 'família'),
      ).map((c) => c.id),
      ['fam'],
    );
    expect(
      apply(
        [family],
        filter: const CultoListFilter(query: '20/09/2026'),
      ).map((c) => c.id),
      ['fam'],
    );
    expect(
      apply(
        [yesterday],
        filter: const CultoListFilter(query: 'ontem'),
      ),
      isEmpty,
    );
  });

  test('turning includePast off drops a range that sits entirely in the past', () {
    final past = CultoDateRange(
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 9, 10),
    );
    expect(CultoListFiltering.constrainRangeToUpcoming(past, now), isNull);
  });

  test('turning includePast off clamps a range that starts in the past', () {
    final mixed = CultoDateRange(
      start: DateTime(2026, 9, 10),
      end: DateTime(2026, 9, 18),
    );
    expect(
      CultoListFiltering.constrainRangeToUpcoming(mixed, now),
      CultoDateRange(start: DateTime(2026, 9, 16), end: DateTime(2026, 9, 18)),
    );
  });

  test('past dates are not selectable until includePast is on', () {
    expect(
      CultoListFiltering.firstSelectableDate(const CultoListFilter(), now),
      DateTime(2026, 9, 16),
    );
    expect(
      CultoListFiltering.firstSelectableDate(
        const CultoListFilter(includePast: true),
        now,
      ),
      DateTime(2021, 9, 16),
    );
  });
}
