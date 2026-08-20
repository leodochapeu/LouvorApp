import 'package:flutter_test/flutter_test.dart';
import 'package:louvor_app/features/cultos/domain/culto_template.dart';
import 'package:louvor_app/features/cultos/domain/culto_template_parser.dart';

void main() {
  const sample = '''
Músicas para o culto de quinta (20/08)
📍Ensaio: 19 horas.

1. Tudo vai bem - Gabriel Rodrigues (B)
https://youtu.be/nBBYAA7GWyw?si=hCCOTNiGTOg5ja61

2. Enquanto eu viver - Diante do Trono (A)
https://youtu.be/0wln451t43Q?si=yKkJF35YBkARlGSN

3. Te seguirei até o fim - Kaleb e Josh (A) 
https://youtu.be/4ks4j9KqXXk?si=YSy0EwC6iX6hyS_d

4. Jeová Jireh - Aline Barros (A)
https://www.youtube.com/watch?v=wXLL6vo8Pxs
''';

  final now = DateTime(2026, 8, 20);

  group('CultoTemplateParser.parse', () {
    test('fills title, date and songs from the group-chat template', () {
      final result = CultoTemplateParser.parse(sample, now: now);

      expect(result.title, 'Culto de quinta');
      expect(result.date, DateTime(2026, 8, 20));
      expect(result.songs, [
        const CultoTemplateSong(
          title: 'Tudo vai bem',
          authors: ['Gabriel Rodrigues'],
          musicalKey: 'B',
          referenceUrl: 'https://youtu.be/nBBYAA7GWyw?si=hCCOTNiGTOg5ja61',
        ),
        const CultoTemplateSong(
          title: 'Enquanto eu viver',
          authors: ['Diante do Trono'],
          musicalKey: 'A',
          referenceUrl: 'https://youtu.be/0wln451t43Q?si=yKkJF35YBkARlGSN',
        ),
        const CultoTemplateSong(
          title: 'Te seguirei até o fim',
          authors: ['Kaleb e Josh'],
          musicalKey: 'A',
          referenceUrl: 'https://youtu.be/4ks4j9KqXXk?si=YSy0EwC6iX6hyS_d',
        ),
        const CultoTemplateSong(
          title: 'Jeová Jireh',
          authors: ['Aline Barros'],
          musicalKey: 'A',
          referenceUrl: 'https://www.youtube.com/watch?v=wXLL6vo8Pxs',
        ),
      ]);
    });

    test('reads an explicit year in the header date', () {
      final result = CultoTemplateParser.parse(
        'Culto da família (03/01/25)\n1. Canção - Autor (C)\nhttps://youtu.be/abc',
        now: now,
      );

      expect(result.title, 'Culto da família');
      expect(result.date, DateTime(2025, 1, 3));
    });

    test('accepts a URL on the same line as the song', () {
      final result = CultoTemplateParser.parse(
        '1. Título - Autor (Dm) https://youtu.be/abc123',
        now: now,
      );

      expect(
        result.songs.single,
        const CultoTemplateSong(
          title: 'Título',
          authors: ['Autor'],
          musicalKey: 'Dm',
          referenceUrl: 'https://youtu.be/abc123',
        ),
      );
    });

    test('keeps songs without author or key', () {
      final result = CultoTemplateParser.parse(
        '1. Amazing Grace\nhttps://youtube.com/watch?v=xyz',
        now: now,
      );

      expect(
        result.songs.single,
        const CultoTemplateSong(
          title: 'Amazing Grace',
          authors: [],
          referenceUrl: 'https://youtube.com/watch?v=xyz',
        ),
      );
    });

    test('splits authors on comma and accepts an en-dash separator', () {
      final result = CultoTemplateParser.parse(
        '1. Grande é o Senhor – Adhemar de Campos, Aline Barros (G)',
        now: now,
      );

      expect(result.songs.single.title, 'Grande é o Senhor');
      expect(result.songs.single.authors, ['Adhemar de Campos', 'Aline Barros']);
      expect(result.songs.single.musicalKey, 'G');
    });

    test('never keeps the musical key inside the author name', () {
      final result = CultoTemplateParser.parse(
        '1. Tudo vai bem - Gabriel Rodrigues (B)\nhttps://youtu.be/abc',
        now: now,
      );

      expect(result.songs.single.authors, ['Gabriel Rodrigues']);
      expect(result.songs.single.musicalKey, 'B');
    });

    test('strips a key glued to the author even with odd parentheses', () {
      final result = CultoTemplateParser.parse(
        '1. Tudo vai bem - Gabriel Rodrigues（B）\nhttps://youtu.be/abc',
        now: now,
      );

      expect(result.songs.single.authors, ['Gabriel Rodrigues']);
      expect(result.songs.single.musicalKey, 'B');
    });

    test('returns an empty template when nothing matches', () {
      final result = CultoTemplateParser.parse('só um recado no grupo', now: now);

      expect(result.isEmpty, isTrue);
      expect(result.songs, isEmpty);
    });
  });
}
