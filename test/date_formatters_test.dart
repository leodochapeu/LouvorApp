import 'package:flutter_test/flutter_test.dart';
import 'package:louvor_app/core/utils/date_formatters.dart';

void main() {
  final date = DateTime(2026, 8, 24);

  test('short formats as dd/MM/yyyy', () {
    expect(DateFormatters.short(date), '24/08/2026');
  });

  test('long formats weekday and month in Portuguese', () {
    expect(DateFormatters.long(date), 'segunda-feira, 24 de agosto de 2026');
  });

  test('toIsoDate / fromIsoDate round-trip the calendar day', () {
    final iso = DateFormatters.toIsoDate(date);
    expect(iso, '2026-08-24');

    final parsed = DateFormatters.fromIsoDate(iso);
    expect(parsed.year, 2026);
    expect(parsed.month, 8);
    expect(parsed.day, 24);
  });
}
