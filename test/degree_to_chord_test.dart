import 'package:flutter_test/flutter_test.dart';
import 'package:louvor_app/features/songs/domain/degree_to_chord.dart';
import 'package:louvor_app/features/songs/domain/entities/song_line.dart';

void main() {
  group('DegreeToChord.convert', () {
    test('maps C major field, including slash bass without m', () {
      expect(DegreeToChord.convert('1 6 4 1/3', 'C'), 'C Am F C/E');
    });

    test('maps every degree of C major', () {
      expect(DegreeToChord.convert('1 2 3 4 5 6 7', 'C'), 'C Dm Em F G Am Bm');
    });

    test('uses the given key, not a hard-coded C', () {
      expect(DegreeToChord.convert('1 6 4 1/3', 'G'), 'G Em C G/B');
      expect(DegreeToChord.convert('1 6 4 1/3', 'F'), 'F Dm Bb F/A');
    });

    test('rotates the field for a minor key', () {
      expect(DegreeToChord.convert('1 6 4 5', 'Am'), 'Am F Dm Em');
      expect(DegreeToChord.convert('1 2 3 4 5 6 7', 'Am'), 'Am Bm C Dm Em F G');
    });

    test('leaves non-digit characters in place', () {
      expect(DegreeToChord.convert('1~ 4 5', 'C'), 'C~ F G');
      expect(DegreeToChord.convert('1  6  4', 'C'), 'C  Am  F');
      expect(DegreeToChord.convert('(1) 5', 'C'), '(C) G');
    });

    test('does not double an explicit m already on the degree', () {
      expect(DegreeToChord.convert('6m', 'C'), 'Am');
      expect(DegreeToChord.convert('5m', 'C'), 'Gm');
    });

    test('does not add m to a bass note even when the degree is minor', () {
      expect(DegreeToChord.convert('1/3', 'C'), 'C/E');
      expect(DegreeToChord.convert('6/1', 'C'), 'Am/C');
      expect(DegreeToChord.convert('1 / 3', 'C'), 'C / E');
    });

    test('keeps an explicit m on a bass note (does not strip it)', () {
      expect(DegreeToChord.convert('1/3m', 'C'), 'C/Em');
    });

    test('applies b/# accidentals to the degree note', () {
      expect(DegreeToChord.convert('1 b7 4', 'C'), 'C Bbm F');
      expect(DegreeToChord.convert('1 #4 5', 'C'), 'C F# G');
    });

    test('returns the original string when the key is missing or invalid', () {
      expect(DegreeToChord.convert('1 6 4', ''), '1 6 4');
      expect(DegreeToChord.convert('1 6 4', 'xyz'), '1 6 4');
    });

    test('leaves a line that is already note names unchanged', () {
      expect(DegreeToChord.convert('C Am F G', 'C'), 'C Am F G');
    });
  });

  group('DegreeToChord.convertLines', () {
    test('only rewrites cifra lines', () {
      const lines = [
        SongLine(type: SongLineType.sessao, content: 'Refrão'),
        SongLine(type: SongLineType.cifra, content: '1 6 4 5'),
        SongLine(type: SongLineType.letra, content: 'Grande é o Senhor'),
      ];

      expect(DegreeToChord.convertLines(lines, 'C'), const [
        SongLine(type: SongLineType.sessao, content: 'Refrão'),
        SongLine(type: SongLineType.cifra, content: 'C Am F G'),
        SongLine(type: SongLineType.letra, content: 'Grande é o Senhor'),
      ]);
    });
  });
}
