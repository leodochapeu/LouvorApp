import 'package:flutter_test/flutter_test.dart';
import 'package:louvor_app/features/songs/domain/entities/song_line.dart';
import 'package:louvor_app/features/songs/domain/lyrics_parser.dart';

void main() {
  group('LyricsParser.parse', () {
    test('tags each marker to its type', () {
      const raw = '> Refrão\n'
          '|| C  Am  F  G ||\n'
          '_"Eu sei que tu és bom"_\n'
          '(2x)';

      final lines = LyricsParser.parse(raw);

      expect(lines, [
        const SongLine(type: SongLineType.sessao, content: 'Refrão'),
        const SongLine(type: SongLineType.cifra, content: 'C  Am  F  G'),
        const SongLine(type: SongLineType.letra, content: 'Eu sei que tu és bom'),
        const SongLine(type: SongLineType.extras, content: '(2x)'),
      ]);
    });

    test('preserves blank lines as empty extras entries', () {
      final lines = LyricsParser.parse('> Estrofe\n\n_"letra"_');

      expect(lines, [
        const SongLine(type: SongLineType.sessao, content: 'Estrofe'),
        const SongLine(type: SongLineType.extras, content: ''),
        const SongLine(type: SongLineType.letra, content: 'letra'),
      ]);
    });

    test('accepts scale-degree chords too', () {
      final lines = LyricsParser.parse('|| 1 6 4 5 ||');
      expect(lines.single, const SongLine(type: SongLineType.cifra, content: '1 6 4 5'));
    });

    test('trims surrounding whitespace before matching markers', () {
      final lines = LyricsParser.parse('   >   Ponte   ');
      expect(lines.single, const SongLine(type: SongLineType.sessao, content: 'Ponte'));
    });
  });

  group('LyricsParser.toRawText', () {
    test('is the inverse of parse for a full round trip', () {
      const raw = '> Introdução\n'
          '|| C Am F G ||\n'
          '_"Grande é o Senhor"_\n'
          '(repete 2x)';

      final roundTripped = LyricsParser.toRawText(LyricsParser.parse(raw));

      expect(roundTripped, raw);
    });
  });
}
