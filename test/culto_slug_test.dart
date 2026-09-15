import 'package:flutter_test/flutter_test.dart';
import 'package:louvor_app/features/cultos/domain/culto_slug.dart';

void main() {
  group('CultoSlug.from', () {
    test('builds kebab-case from title and date', () {
      expect(
        CultoSlug.from(title: 'Culto da Família', date: DateTime(2026, 9, 15)),
        'culto-da-familia-2026-09-15',
      );
    });

    test('falls back when the title has no slug-able characters', () {
      expect(
        CultoSlug.from(title: '!!!', date: DateTime(2026, 9, 15)),
        'culto-2026-09-15',
      );
    });
  });
}
