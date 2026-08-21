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

    test('keeps a chord line as cifra when a parenthetical follows ||', () {
      final lines = LyricsParser.parse('|| 4 1 5 {3} || (³*)');

      expect(
        lines.single,
        const SongLine(
          type: SongLineType.cifra,
          content: '4 1 5 {3}',
          suffix: '(³*)',
        ),
      );
    });

    test('keeps bar-separated chords as cifra with a trailing repeat mark', () {
      final lines = LyricsParser.parse('|| 4 1 4 1 | 4 1 4 1 || (²*)');

      expect(
        lines.single,
        const SongLine(
          type: SongLineType.cifra,
          content: '4 1 4 1 | 4 1 4 1',
          suffix: '(²*)',
        ),
      );
    });

    test('keeps lyrics as letra when a repeat mark follows the closing quote', () {
      final lines = LyricsParser.parse('_\"No grande mover..\"_ ²*');

      expect(
        lines.single,
        const SongLine(
          type: SongLineType.letra,
          content: 'No grande mover..',
          suffix: '²*',
        ),
      );
    });
  });

  group('LyricsParser.inlineRuns', () {
    test('marks ~text~ as strikethrough and leaves the rest alone', () {
      expect(LyricsParser.inlineRuns('~Espontâneo~'), const [
        (text: 'Espontâneo', strikethrough: true),
      ]);
      expect(LyricsParser.inlineRuns('antes ~meio~ depois'), const [
        (text: 'antes ', strikethrough: false),
        (text: 'meio', strikethrough: true),
        (text: ' depois', strikethrough: false),
      ]);
    });

    test('does not strike through sustain tildes next to a degree', () {
      expect(LyricsParser.inlineRuns('{3 5 6 8~ 9 6~ 5~}'), const [
        (text: '{3 5 6 8~ 9 6~ 5~}', strikethrough: false),
      ]);
    });

    test('still strikes ~text~ on a line that also has sustain tildes', () {
      expect(LyricsParser.inlineRuns('8~ 6~ ~Espontâneo~'), const [
        (text: '8~ 6~ ', strikethrough: false),
        (text: 'Espontâneo', strikethrough: true),
      ]);
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

    test('round-trips trailing annotations on cifra and letra', () {
      const raw = '|| 4 1 5 {3} || (³*)\n'
          '_"No grande mover.."_ ²*';

      expect(LyricsParser.toRawText(LyricsParser.parse(raw)), raw);
    });
  });
}
