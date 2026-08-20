import 'package:flutter_test/flutter_test.dart';
import 'package:louvor_app/features/songs/domain/song_slug.dart';

void main() {
  group('SongSlug.from', () {
    test('builds kebab-case from title and authors', () {
      expect(
        SongSlug.from(title: 'Quão Grande É o Meu Deus', authors: ['Nívea Soares']),
        'quao-grande-e-o-meu-deus-nivea-soares',
      );
    });

    test('is independent of author order', () {
      const title = 'Grande é o Senhor';
      const expected = 'grande-e-o-senhor-adhemar-de-campos-aline-barros';
      expect(
        SongSlug.from(title: title, authors: ['Adhemar de Campos', 'Aline Barros']),
        expected,
      );
      expect(
        SongSlug.from(title: title, authors: ['Aline Barros', 'Adhemar de Campos']),
        expected,
      );
    });

    test('ignores extra spaces, punctuation and casing', () {
      expect(
        SongSlug.from(title: '  O Rei  Está Voltando! ', authors: ['  FERNANDINHO  ']),
        'o-rei-esta-voltando-fernandinho',
      );
    });

    test('uses only the title when there are no authors', () {
      expect(SongSlug.from(title: 'Amazing Grace', authors: const []), 'amazing-grace');
    });

    test('falls back when nothing slug-able remains', () {
      expect(SongSlug.from(title: '!!!', authors: const []), SongSlug.fallback);
    });
  });
}
