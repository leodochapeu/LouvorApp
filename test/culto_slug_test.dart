import 'package:flutter_test/flutter_test.dart';
import 'package:louvor_app/features/cultos/domain/culto_slug.dart';

void main() {
  group('CultoSlug.from', () {
    test('builds kebab-case from title, day-month and id', () {
      expect(
        CultoSlug.from(
          title: 'Culto de Domingo',
          date: DateTime(2026, 8, 30),
          id: '173f5f23-ff0e-4142-96b8-eeaabac8d642',
        ),
        'culto-de-domingo-30-08-173f5f23-ff0e-4142-96b8-eeaabac8d642',
      );
    });

    test('falls back when the title has no slug-able characters', () {
      expect(
        CultoSlug.from(
          title: '!!!',
          date: DateTime(2026, 9, 15),
          id: 'culto-1',
        ),
        'culto-15-09-culto-1',
      );
    });

    test('does not repeat the date when the title already includes it', () {
      expect(
        CultoSlug.from(
          title: 'Culto de ceia (06/09)',
          date: DateTime(2026, 9, 6),
          id: '92a0f4f9-193b-4547-8e78-91606baeca7c',
        ),
        'culto-de-ceia-06-09-92a0f4f9-193b-4547-8e78-91606baeca7c',
      );
    });
  });

  group('CultoSlug.idFrom', () {
    test('reads the uuid at the end of a culto slug', () {
      expect(
        CultoSlug.idFrom(
          'culto-de-domingo-30-08-173f5f23-ff0e-4142-96b8-eeaabac8d642',
        ),
        '173f5f23-ff0e-4142-96b8-eeaabac8d642',
      );
    });
  });
}
