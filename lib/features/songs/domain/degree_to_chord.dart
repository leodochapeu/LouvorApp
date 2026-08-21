import 'entities/song_line.dart';

/// Projects Nashville-style scale degrees (`1`–`7`) onto chord names using
/// the diatonic harmonic field of a key.
///
/// Major example in C: `1 6 4 1/3` → `C Am F C/E`.
///
/// Suffixes right after a degree are modifiers and are consumed:
/// - `b` / `#` shift the pitch a semitone (`7b` in D: C# → C)
/// - `M` / `m` force major or minor (`3M` in D: F#m → F#)
///
/// Combined: `7bM` in D is C (flattened and forced major). Other characters
/// (`/`, `~`, parentheses, …) are left untouched. Bass notes after `/` do not
/// receive a harmonic-field `m` — `1/3` is `C/E`, not `C/Em`.
abstract final class DegreeToChord {
  /// Converts every [SongLineType.cifra] line; other line types are kept as-is.
  static List<SongLine> convertLines(List<SongLine> lines, String key) {
    final field = _HarmonicField.tryParse(key);
    if (field == null) return lines;

    return [
      for (final line in lines)
        if (line.type == SongLineType.cifra)
          SongLine(
            type: line.type,
            content: _convertContent(line.content, field),
            suffix: line.suffix,
          )
        else
          line,
    ];
  }

  /// Converts a single chord-line string. Returns [content] unchanged when
  /// [key] cannot be parsed.
  static String convert(String content, String key) {
    final field = _HarmonicField.tryParse(key);
    if (field == null) return content;
    return _convertContent(content, field);
  }

  static String _convertContent(String content, _HarmonicField field) {
    final buffer = StringBuffer();
    var i = 0;

    while (i < content.length) {
      final token = _readToken(content, i);
      if (token != null) {
        buffer.write(
          field.chord(
            token.degree,
            accidental: token.accidental,
            asBass: _isBassPosition(content, token.start),
            quality: token.quality,
          ),
        );
        i = token.end;
        continue;
      }

      buffer.write(content[i]);
      i++;
    }

    return buffer.toString();
  }

  /// Reads a degree plus its optional accidental and quality suffixes.
  ///
  /// Accepts `b7` / `#4` (accidental before) and `7bM` / `3M` (after). An
  /// accidental after the digit wins when both are present.
  static _DegreeToken? _readToken(String source, int index) {
    var i = index;
    var accidental = 0;

    final leading = _accidentalValue(source, i);
    if (leading != 0 && i + 1 < source.length && _isDegree(source[i + 1])) {
      accidental = leading;
      i++;
    }

    if (i >= source.length || !_isDegree(source[i])) return null;

    final degree = int.parse(source[i]);
    i++;

    final trailing = _accidentalValue(source, i);
    if (trailing != 0) {
      accidental = trailing;
      i++;
    }

    final quality = i < source.length
        ? switch (source[i]) {
            'M' => _ChordQuality.major,
            'm' => _ChordQuality.minor,
            _ => null,
          }
        : null;
    if (quality != null) i++;

    return _DegreeToken(
      degree: degree,
      accidental: accidental,
      quality: quality,
      start: index,
      end: i,
    );
  }

  static int _accidentalValue(String source, int index) {
    if (index >= source.length) return 0;
    return switch (source[index]) {
      'b' || '♭' => -1,
      '#' || '♯' => 1,
      _ => 0,
    };
  }

  static bool _isDegree(String char) =>
      char.length == 1 && char.compareTo('1') >= 0 && char.compareTo('7') <= 0;

  /// True when the token starting at [index] is the bass of a slash chord
  /// (`1/3`, `1 / 3`).
  static bool _isBassPosition(String source, int index) {
    var i = index - 1;
    while (i >= 0 && source[i] == ' ') {
      i--;
    }
    return i >= 0 && source[i] == '/';
  }
}

enum _ChordQuality { major, minor }

class _DegreeToken {
  const _DegreeToken({
    required this.degree,
    required this.accidental,
    required this.quality,
    required this.start,
    required this.end,
  });

  final int degree;
  final int accidental;
  final _ChordQuality? quality;
  final int start;
  final int end;
}

/// Diatonic harmonic field of a major or minor key.
///
/// Qualities follow the common worship-cifra convention (vii as minor, not
/// diminished): C → C Dm Em F G Am Bm. A minor key is the relative major's
/// field rotated so the sixth degree becomes the tonic: Am → Am Bm C Dm Em F G.
class _HarmonicField {
  _HarmonicField._(this._notes, this._isMinor);

  final List<String> _notes;
  final List<bool> _isMinor;

  static const _letters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  static const _naturalPc = {
    'C': 0,
    'D': 2,
    'E': 4,
    'F': 5,
    'G': 7,
    'A': 9,
    'B': 11,
  };
  static const _majorIsMinor = [false, true, true, false, false, true, true];
  static const _majorIntervals = [0, 2, 4, 5, 7, 9, 11];

  static _HarmonicField? tryParse(String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return null;

    final isMinorKey = _isMinorKeyName(trimmed);
    final tonic = isMinorKey ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    if (_pitchClass(tonic) == null) return null;

    final majorTonic = isMinorKey ? _relativeMajor(tonic) : tonic;
    if (_pitchClass(majorTonic) == null) return null;

    var notes = _majorScale(majorTonic);
    var isMinor = List<bool>.from(_majorIsMinor);

    if (isMinorKey) {
      notes = [...notes.skip(5), ...notes.take(5)];
      isMinor = [...isMinor.skip(5), ...isMinor.take(5)];
    }

    return _HarmonicField._(notes, isMinor);
  }

  String chord(
    int degree, {
    required int accidental,
    required bool asBass,
    _ChordQuality? quality,
  }) {
    final index = degree - 1;
    var note = _notes[index];
    if (accidental != 0) {
      final letter = _parseNote(note)!.letter;
      note = _formatNote(letter, (_pitchClass(note)! + accidental) % 12);
    }

    final isMinor = switch (quality) {
      _ChordQuality.major => false,
      _ChordQuality.minor => true,
      null => !asBass && _isMinor[index],
    };

    return isMinor ? '${note}m' : note;
  }

  static bool _isMinorKeyName(String key) {
    if (!key.endsWith('m')) return false;
    final tonic = key.substring(0, key.length - 1);
    return tonic.isNotEmpty && _pitchClass(tonic) != null;
  }

  static String _relativeMajor(String minorTonic) {
    final parsed = _parseNote(minorTonic)!;
    final thirdLetter = _letters[(_letters.indexOf(parsed.letter) + 2) % 7];
    return _formatNote(thirdLetter, (_pitchClass(minorTonic)! + 3) % 12);
  }

  static List<String> _majorScale(String tonic) {
    final parsed = _parseNote(tonic)!;
    final tonicPc = _pitchClass(tonic)!;
    final start = _letters.indexOf(parsed.letter);
    return List.generate(7, (i) {
      final letter = _letters[(start + i) % 7];
      return _formatNote(letter, (tonicPc + _majorIntervals[i]) % 12);
    });
  }

  static ({String letter, String accidental})? _parseNote(String note) {
    if (note.isEmpty) return null;
    final letter = note[0].toUpperCase();
    if (!_naturalPc.containsKey(letter)) return null;
    return (letter: letter, accidental: note.substring(1));
  }

  static int? _pitchClass(String note) {
    final parsed = _parseNote(note);
    if (parsed == null) return null;
    final offset = switch (parsed.accidental) {
      '' => 0,
      '#' => 1,
      '##' => 2,
      'b' => -1,
      'bb' => -2,
      _ => null,
    };
    if (offset == null) return null;
    return (_naturalPc[parsed.letter]! + offset + 12) % 12;
  }

  static String _formatNote(String letter, int targetPc) {
    final natural = _naturalPc[letter]!;
    var diff = (targetPc - natural) % 12;
    if (diff > 6) diff -= 12;
    return switch (diff) {
      0 => letter,
      1 => '$letter#',
      2 => '$letter##',
      -1 => '${letter}b',
      -2 => '${letter}bb',
      _ => letter,
    };
  }
}
