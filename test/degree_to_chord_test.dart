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

    test('maps every degree of D major', () {
      expect(DegreeToChord.convert('1 2 3 4 5 6 7', 'D'), 'D Em F#m G A Bm C#m');
    });

    test('uses readable enharmonics instead of F## / E# / G## in A#', () {
      expect(
        DegreeToChord.convert('6 5 4 | 6 5 4', 'A#'),
        'Gm F D# | Gm F D#',
      );
      expect(
        DegreeToChord.convert('1 2 3 4 5 6 7', 'A#'),
        'A# Cm Dm D# F Gm Am',
      );
      expect(
        DegreeToChord.convert('{ 6 5/7 1 | 2 1 5/7 }', 'A#'),
        '{ Gm F/A A# | Cm A# F/A }',
      );
    });

    test('uses readable enharmonics for E# and Cb in F# and Gb', () {
      expect(
        DegreeToChord.convert('1 2 3 4 5 6 7', 'F#'),
        'F# G#m A#m B C# D#m Fm',
      );
      expect(
        DegreeToChord.convert('1 2 3 4 5 6 7', 'Gb'),
        'Gb Abm Bbm B Db Ebm Fm',
      );
    });

    test('maps G and F major slash chords', () {
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

    test('explicit m/M override the harmonic-field quality', () {
      expect(DegreeToChord.convert('6m', 'C'), 'Am');
      expect(DegreeToChord.convert('5m', 'C'), 'Gm');
      expect(DegreeToChord.convert('6M', 'C'), 'A');
      expect(DegreeToChord.convert('3M', 'D'), 'F#');
    });

    test('does not add m to a bass note even when the degree is minor', () {
      expect(DegreeToChord.convert('1/3', 'C'), 'C/E');
      expect(DegreeToChord.convert('6/1', 'C'), 'Am/C');
      expect(DegreeToChord.convert('1 / 3', 'C'), 'C / E');
    });

    test('explicit m on a bass note forces minor', () {
      expect(DegreeToChord.convert('1/3m', 'C'), 'C/Em');
    });

    test('applies b/# accidentals before or after the degree', () {
      expect(DegreeToChord.convert('1 b7 4', 'C'), 'C Bbm F');
      expect(DegreeToChord.convert('1 7b 4', 'C'), 'C Bbm F');
      expect(DegreeToChord.convert('1 #4 5', 'C'), 'C F# G');
    });

    test('combines accidental and quality suffixes as in 7bM', () {
      // D: 1=D 2=Em 3=F#m 4=G 5=A 6=Bm 7=C#m
      expect(DegreeToChord.convert('7bM', 'D'), 'C');
      expect(DegreeToChord.convert('7bM~', 'D'), 'C~');
      expect(DegreeToChord.convert('{ 6 5 4 1/3 } 7bM~', 'D'), '{ Bm A G D/F# } C~');
      expect(DegreeToChord.convert('4  5/4 | 3M 6 | 2 5 1', 'D'), 'G  A/G | F# Bm | Em A D');
      expect(DegreeToChord.convert('1  3  4  (6M)  2  1  5', 'D'), 'D  F#m  G  (B)  Em  D  A');
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

    test('does not convert a parenthetical suffix after the chord markers', () {
      const lines = [
        SongLine(
          type: SongLineType.cifra,
          content: '4 1 5 {3}',
          suffix: '(2*)',
        ),
      ];

      expect(DegreeToChord.convertLines(lines, 'C'), const [
        SongLine(
          type: SongLineType.cifra,
          content: 'F C G {Em}',
          suffix: '(2*)',
        ),
      ]);
    });
  });
}
