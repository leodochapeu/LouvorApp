import 'package:flutter_test/flutter_test.dart';
import 'package:louvor_app/core/share/share_preview.dart';
import 'package:louvor_app/core/utils/route_id.dart';

void main() {
  group('SharePreview', () {
    test('builds a song description with authors and key', () {
      expect(
        SharePreview.songDescription(
          title: 'Grande é o Senhor',
          authors: const ['Adhemar de Campos'],
          originalKey: 'G',
        ),
        'Cifra e letra de Grande é o Senhor, de Adhemar de Campos. Tom original: G.',
      );
    });

    test('omits authors and key when they are empty', () {
      expect(
        SharePreview.songDescription(
          title: 'Amazing Grace',
          authors: const [],
        ),
        'Cifra e letra de Amazing Grace.',
      );
    });

    test('builds a culto description with date and song count', () {
      expect(
        SharePreview.cultoDescription(
          title: 'Culto da Família',
          date: DateTime(2026, 9, 15),
          songCount: 3,
        ),
        'Setlist de Culto da Família · terça-feira, 15 de setembro de 2026 · 3 músicas.',
      );
    });

    test('uses Louvor App in page titles', () {
      expect(SharePreview.songTitle('Grande é o Senhor'), 'Grande é o Senhor · Louvor App');
      expect(SharePreview.pageTitle('Cultos'), 'Cultos · Louvor App');
    });
  });

  group('RouteId.isUuid', () {
    test('detects a UUID', () {
      expect(RouteId.isUuid('40cd5a9e-8998-437d-9e3a-b432ecf56133'), isTrue);
    });

    test('rejects a slug', () {
      expect(RouteId.isUuid('grande-e-o-senhor-adhemar-de-campos'), isFalse);
    });

    test('reads a uuid at the end of a culto slug', () {
      expect(
        RouteId.uuidAtEnd(
          'culto-de-domingo-30-08-173f5f23-ff0e-4142-96b8-eeaabac8d642',
        ),
        '173f5f23-ff0e-4142-96b8-eeaabac8d642',
      );
    });
  });
}
