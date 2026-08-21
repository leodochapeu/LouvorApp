import 'entities/song_line.dart';

/// Converts between the plain text a person pastes/types into the song form
/// and the structured [SongLine] list that gets stored as jsonb.
///
/// Markup recognized per line (checked in this order):
///   - Section:  `> Refrão`                  -> [SongLineType.sessao]
///   - Chords:   `|| 1 6 4 5 ||`              -> [SongLineType.cifra]
///     Trailing notes after the closing `||` (e.g. `(³*)`) stay as [SongLine.suffix].
///   - Lyrics:   `_"Eu sei que tu és bom"_`   -> [SongLineType.letra]
///     Trailing notes after `"_` (e.g. `²*`) stay as [SongLine.suffix].
///   - Anything else (including blank lines)  -> [SongLineType.extras]
///
/// Inline `~texto~` is kept in [SongLine.content] and rendered as strikethrough.
/// A tilde glued to a degree (`8~`, `~4`) is a sustain mark, not strikethrough.
/// Inline `_"texto"_` is italic, so a section like
/// `> Medley: _"Pai querido.."_ (alteração nossa)` can mix title and lyric.
abstract final class LyricsParser {
  static final RegExp _cifraPattern = RegExp(r'^\|\|(.*)\|\|(.*)$');
  static final RegExp _letraPattern = RegExp(r'^_"(.*)"_(.*)$');

  /// Parses raw multi-line text into an ordered list of tagged lines, one
  /// per line of input (blank lines become empty [SongLineType.extras]
  /// entries, preserving spacing between sections).
  static List<SongLine> parse(String rawText) {
    return rawText.split('\n').map(_parseLine).toList();
  }

  static SongLine _parseLine(String rawLine) {
    final trimmed = rawLine.trim();

    final cifraMatch = _cifraPattern.firstMatch(trimmed);
    if (cifraMatch != null) {
      return SongLine(
        type: SongLineType.cifra,
        content: cifraMatch.group(1)!.trim(),
        suffix: cifraMatch.group(2)!.trim(),
      );
    }

    final letraMatch = _letraPattern.firstMatch(trimmed);
    if (letraMatch != null) {
      return SongLine(
        type: SongLineType.letra,
        content: letraMatch.group(1)!.trim(),
        suffix: letraMatch.group(2)!.trim(),
      );
    }

    if (trimmed.startsWith('>')) {
      return SongLine(
        type: SongLineType.sessao,
        content: trimmed.substring(1).trim(),
      );
    }

    return SongLine(type: SongLineType.extras, content: trimmed);
  }

  /// The inverse of [parse]: rebuilds the marked-up raw text from stored
  /// lines, so the form can be pre-filled when editing an existing song.
  static String toRawText(List<SongLine> lines) {
    return lines.map(_lineToRaw).join('\n');
  }

  static String _lineToRaw(SongLine line) {
    final suffix = line.suffix.isEmpty ? '' : ' ${line.suffix}';
    return switch (line.type) {
      SongLineType.sessao => '> ${line.content}',
      SongLineType.cifra => '|| ${line.content} ||$suffix',
      SongLineType.letra => '_"${line.content}"_$suffix',
      SongLineType.extras => line.content,
    };
  }

  /// Splits [text] into runs, treating `_"foo"_` as italic and `~foo~` as
  /// strikethrough.
  ///
  /// Tildes next to a digit (`8~`, `6~`) stay in the text: they mean the
  /// degree is held, not that a span should be struck through.
  static List<LyricsInlineRun> inlineRuns(String text) {
    if (text.isEmpty) return const [];

    final runs = <LyricsInlineRun>[];
    var cursor = 0;
    var i = 0;
    while (i < text.length) {
      if (_startsLetraMarkup(text, i)) {
        final close = _findLetraClose(text, i + 2);
        if (close > i + 2) {
          if (i > cursor) {
            runs.add(LyricsInlineRun(text.substring(cursor, i)));
          }
          runs.add(LyricsInlineRun(text.substring(i + 2, close), italic: true));
          cursor = close + 2;
          i = cursor;
          continue;
        }
        i++;
        continue;
      }

      if (text[i] != '~' || _isSustainTilde(text, i)) {
        i++;
        continue;
      }

      var close = -1;
      for (var j = i + 1; j < text.length; j++) {
        if (text[j] == '~' && !_isSustainTilde(text, j)) {
          close = j;
          break;
        }
      }
      if (close < 0 || close == i + 1) {
        i++;
        continue;
      }

      if (i > cursor) {
        runs.add(LyricsInlineRun(text.substring(cursor, i)));
      }
      runs.add(LyricsInlineRun(text.substring(i + 1, close), strikethrough: true));
      cursor = close + 1;
      i = cursor;
    }
    if (cursor < text.length) {
      runs.add(LyricsInlineRun(text.substring(cursor)));
    }
    return runs;
  }

  static bool _startsLetraMarkup(String text, int index) =>
      index + 1 < text.length && text[index] == '_' && text[index + 1] == '"';

  static int _findLetraClose(String text, int from) {
    for (var j = from; j + 1 < text.length; j++) {
      if (text[j] == '"' && text[j + 1] == '_') return j;
    }
    return -1;
  }

  /// True when `text[index]` is a `~` sitting beside a degree number.
  static bool _isSustainTilde(String text, int index) {
    if (index > 0 && _isDigit(text[index - 1])) return true;
    if (index + 1 < text.length && _isDigit(text[index + 1])) return true;
    return false;
  }

  static bool _isDigit(String char) =>
      char.length == 1 && char.compareTo('0') >= 0 && char.compareTo('9') <= 0;
}

/// One styled span inside a song line, after inline markup is interpreted.
class LyricsInlineRun {
  const LyricsInlineRun(
    this.text, {
    this.strikethrough = false,
    this.italic = false,
  });

  final String text;
  final bool strikethrough;
  final bool italic;

  @override
  bool operator ==(Object other) =>
      other is LyricsInlineRun &&
      text == other.text &&
      strikethrough == other.strikethrough &&
      italic == other.italic;

  @override
  int get hashCode => Object.hash(text, strikethrough, italic);
}
