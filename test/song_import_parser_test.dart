import 'package:flutter_test/flutter_test.dart';
import 'package:louvor_app/features/songs/domain/entities/song_line.dart';
import 'package:louvor_app/features/songs/domain/lyrics_parser.dart';
import 'package:louvor_app/features/songs/domain/song_import.dart';
import 'package:louvor_app/features/songs/domain/song_import_parser.dart';

void main() {
  const sample = '''
{
  "musica": {
    "titulo": "Te Seguirei Até o Fim",
    "artista": "Kaleb e Josh",
    "versao": "Verbo",
    "tom_original": "B",
    "tom": "A"
  },
  "estrutura": [
    {
      "tipo": "introducao",
      "descricao": "Dedilhado violão 🎸",
      "acordes": ["4", "5", "6", "3"],
      "repeticoes": 4
    },
    {
      "tipo": "estrofe",
      "numero": 1,
      "trecho": "Na minha vida..",
      "acordes": ["4", "5", "1"],
      "repeticoes": 1
    },
    {
      "tipo": "estrofe",
      "numero": 1,
      "acordes": ["4", "5", "6", "3"],
      "repeticoes": 4
    },
    {
      "tipo": "refrão",
      "numero": 1,
      "trecho": "Com todo o meu coração..",
      "partes": [
        {
          "acordes": ["4", "5", "1"],
          "repeticoes": 1
        },
        {
          "acordes": ["4", "5"],
          "repeticoes": 1
        },
        {
          "acordes": ["4/6", "5/7", "1", "3"],
          "repeticoes": 1
        },
        {
          "acordes": ["4", "5"],
          "repeticoes": 1
        }
      ]
    },
    {
      "tipo": "estrofe",
      "numero": 2,
      "referencia": "estrofe_1",
      "repeticoes": 4
    },
    {
      "tipo": "refrão",
      "numero": 2,
      "referencia": "refrão_1",
      "repeticoes": 2
    },
    {
      "tipo": "ponte",
      "numero": 1,
      "trecho": "Te seguirei até o fim..",
      "acordes": ["4", "5"],
      "repeticoes": 4
    },
    {
      "tipo": "interludio",
      "descricao": "ooh oh",
      "acordes": ["4", "5"],
      "repeticoes": 1
    },
    {
      "tipo": "ponte",
      "numero": 2,
      "acordes": ["4", "5"],
      "repeticoes": 2
    },
    {
      "tipo": "solo",
      "instrumento": "guitarra 🎸"
    },
    {
      "tipo": "finalizacao"
    }
  ]
}
''';

  group('SongImportParser.parse', () {
    test('fills title, author, keys and lyrics from the sample JSON', () {
      final imported = SongImportParser.parse(sample);

      expect(imported.title, 'Te Seguirei Até o Fim');
      expect(imported.authors, ['Kaleb e Josh']);
      expect(imported.originalKey, 'B');
      expect(imported.currentKey, 'A');

      expect(imported.lines, [
        const SongLine(type: SongLineType.extras, content: '(Verbo)'),
        const SongLine(type: SongLineType.extras, content: ''),
        const SongLine(type: SongLineType.sessao, content: 'Introdução'),
        const SongLine(type: SongLineType.extras, content: 'Dedilhado violão 🎸'),
        const SongLine(
          type: SongLineType.cifra,
          content: '4 5 6 3',
          suffix: '(⁴*)',
        ),
        const SongLine(type: SongLineType.extras, content: ''),
        const SongLine(type: SongLineType.sessao, content: 'Estrofe 1'),
        const SongLine(type: SongLineType.letra, content: 'Na minha vida..'),
        const SongLine(type: SongLineType.cifra, content: '4 5 1'),
        const SongLine(
          type: SongLineType.cifra,
          content: '4 5 6 3',
          suffix: '(⁴*)',
        ),
        const SongLine(type: SongLineType.extras, content: ''),
        const SongLine(type: SongLineType.sessao, content: 'Refrão 1'),
        const SongLine(
          type: SongLineType.letra,
          content: 'Com todo o meu coração..',
        ),
        const SongLine(type: SongLineType.cifra, content: '4 5 1'),
        const SongLine(type: SongLineType.cifra, content: '4 5'),
        const SongLine(type: SongLineType.cifra, content: '4/6 5/7 1 3'),
        const SongLine(type: SongLineType.cifra, content: '4 5'),
        const SongLine(type: SongLineType.extras, content: ''),
        const SongLine(type: SongLineType.sessao, content: 'Estrofe 2'),
        const SongLine(type: SongLineType.letra, content: 'Na minha vida..'),
        const SongLine(type: SongLineType.cifra, content: '4 5 1'),
        const SongLine(
          type: SongLineType.cifra,
          content: '4 5 6 3',
          suffix: '(⁴*)',
        ),
        const SongLine(type: SongLineType.extras, content: ''),
        const SongLine(type: SongLineType.sessao, content: 'Refrão 2'),
        const SongLine(
          type: SongLineType.letra,
          content: 'Com todo o meu coração..',
        ),
        const SongLine(type: SongLineType.cifra, content: '4 5 1'),
        const SongLine(type: SongLineType.cifra, content: '4 5'),
        const SongLine(type: SongLineType.cifra, content: '4/6 5/7 1 3'),
        const SongLine(type: SongLineType.cifra, content: '4 5'),
        const SongLine(type: SongLineType.extras, content: '(2x)'),
        const SongLine(type: SongLineType.extras, content: ''),
        const SongLine(type: SongLineType.sessao, content: 'Ponte 1'),
        const SongLine(
          type: SongLineType.letra,
          content: 'Te seguirei até o fim..',
        ),
        const SongLine(
          type: SongLineType.cifra,
          content: '4 5',
          suffix: '(⁴*)',
        ),
        const SongLine(type: SongLineType.extras, content: ''),
        const SongLine(type: SongLineType.sessao, content: 'Interlúdio'),
        const SongLine(type: SongLineType.extras, content: 'ooh oh'),
        const SongLine(type: SongLineType.cifra, content: '4 5'),
        const SongLine(type: SongLineType.extras, content: ''),
        const SongLine(type: SongLineType.sessao, content: 'Ponte 2'),
        const SongLine(
          type: SongLineType.cifra,
          content: '4 5',
          suffix: '(²*)',
        ),
        const SongLine(type: SongLineType.extras, content: ''),
        const SongLine(type: SongLineType.sessao, content: 'Solo'),
        const SongLine(type: SongLineType.extras, content: 'guitarra 🎸'),
        const SongLine(type: SongLineType.extras, content: ''),
        const SongLine(type: SongLineType.sessao, content: 'Finalização'),
      ]);
    });

    test('round-trips imported lines through the lyrics markup', () {
      final imported = SongImportParser.parse(sample);
      final raw = LyricsParser.toRawText(imported.lines);

      expect(
        raw,
        '(Verbo)\n'
        '\n'
        '> Introdução\n'
        'Dedilhado violão 🎸\n'
        '|| 4 5 6 3 || (⁴*)\n'
        '\n'
        '> Estrofe 1\n'
        '_"Na minha vida.."_\n'
        '|| 4 5 1 ||\n'
        '|| 4 5 6 3 || (⁴*)\n'
        '\n'
        '> Refrão 1\n'
        '_"Com todo o meu coração.."_\n'
        '|| 4 5 1 ||\n'
        '|| 4 5 ||\n'
        '|| 4/6 5/7 1 3 ||\n'
        '|| 4 5 ||\n'
        '\n'
        '> Estrofe 2\n'
        '_"Na minha vida.."_\n'
        '|| 4 5 1 ||\n'
        '|| 4 5 6 3 || (⁴*)\n'
        '\n'
        '> Refrão 2\n'
        '_"Com todo o meu coração.."_\n'
        '|| 4 5 1 ||\n'
        '|| 4 5 ||\n'
        '|| 4/6 5/7 1 3 ||\n'
        '|| 4 5 ||\n'
        '(2x)\n'
        '\n'
        '> Ponte 1\n'
        '_"Te seguirei até o fim.."_\n'
        '|| 4 5 || (⁴*)\n'
        '\n'
        '> Interlúdio\n'
        'ooh oh\n'
        '|| 4 5 ||\n'
        '\n'
        '> Ponte 2\n'
        '|| 4 5 || (²*)\n'
        '\n'
        '> Solo\n'
        'guitarra 🎸\n'
        '\n'
        '> Finalização',
      );
      expect(LyricsParser.parse(raw), imported.lines);
    });

    test('does not set an altered key when tom equals tom_original', () {
      final imported = SongImportParser.parse('''
{
  "musica": {
    "titulo": "Canção",
    "artista": "Autor",
    "tom_original": "C",
    "tom": "C"
  },
  "estrutura": []
}
''');

      expect(imported.originalKey, 'C');
      expect(imported.currentKey, isNull);
    });

    test('uses tom as original key when tom_original is missing', () {
      final imported = SongImportParser.parse('''
{
  "musica": { "titulo": "Canção", "tom": "dm" },
  "estrutura": []
}
''');

      expect(imported.originalKey, 'Dm');
      expect(imported.currentKey, isNull);
    });

    test('unwraps a markdown code fence', () {
      final imported = SongImportParser.parse('''
```json
{"musica": {"titulo": "Canção", "artista": "Autor"}, "estrutura": []}
```
''');

      expect(imported.title, 'Canção');
      expect(imported.authors, ['Autor']);
    });

    test('splits multiple authors on commas only', () {
      final imported = SongImportParser.parse('''
{
  "musica": { "titulo": "Canção", "artista": "Kaleb e Josh, Verbo" },
  "estrutura": []
}
''');

      expect(imported.authors, ['Kaleb e Josh', 'Verbo']);
    });

    test('falls back to an extras note when the reference is unknown', () {
      final imported = SongImportParser.parse('''
{
  "musica": { "titulo": "Canção" },
  "estrutura": [
    {
      "tipo": "estrofe",
      "numero": 2,
      "referencia": "estrofe_1",
      "repeticoes": 2
    }
  ]
}
''');

      expect(imported.lines, [
        const SongLine(type: SongLineType.sessao, content: 'Estrofe 2'),
        const SongLine(
          type: SongLineType.extras,
          content: '(igual à Estrofe 1) (²*)',
        ),
      ]);
    });

    test('throws a Portuguese error for invalid JSON', () {
      expect(
        () => SongImportParser.parse('{ musica: }'),
        throwsA(
          isA<SongImportException>().having(
            (error) => error.message,
            'message',
            contains('JSON inválido'),
          ),
        ),
      );
    });

    test('throws when musica is missing', () {
      expect(
        () => SongImportParser.parse('{"estrutura": []}'),
        throwsA(
          isA<SongImportException>().having(
            (error) => error.message,
            'message',
            contains('"musica"'),
          ),
        ),
      );
    });
  });
}
