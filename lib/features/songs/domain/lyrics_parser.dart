import 'entities/song_line.dart';

/// Converts between the plain text a person pastes/types into the song form
/// and the structured [SongLine] list that gets stored as jsonb.
///
/// Markup recognized per line (checked in this order):
///   - Section:  `> Refrão`                  -> [SongLineType.sessao]
///   - Chords:   `|| 1 6 4 5 ||`              -> [SongLineType.cifra]
///   - Lyrics:   `_"Eu sei que tu és bom"_`   -> [SongLineType.letra]
///   - Anything else (including blank lines)  -> [SongLineType.extras]
abstract final class LyricsParser {
  static final RegExp _cifraPattern = RegExp(r'^\|\|(.*)\|\|$');
  static final RegExp _letraPattern = RegExp(r'^_"(.*)"_$');

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
      return SongLine(type: SongLineType.cifra, content: cifraMatch.group(1)!.trim());
    }

    final letraMatch = _letraPattern.firstMatch(trimmed);
    if (letraMatch != null) {
      return SongLine(type: SongLineType.letra, content: letraMatch.group(1)!.trim());
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
    return switch (line.type) {
      SongLineType.sessao => '> ${line.content}',
      SongLineType.cifra => '|| ${line.content} ||',
      SongLineType.letra => '_"${line.content}"_',
      SongLineType.extras => line.content,
    };
  }
}
