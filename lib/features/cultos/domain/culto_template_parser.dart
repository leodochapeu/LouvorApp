import '../../../core/constants/musical_keys.dart';
import '../../../core/utils/url_utils.dart';
import 'culto_template.dart';

/// Reads the common group-chat setlist format:
///
/// ```
/// Músicas para o culto de quinta (20/08)
/// 📍Ensaio: 19 horas.
///
/// 1. Título - Autor (B)
/// https://youtu.be/...
/// ```
abstract final class CultoTemplateParser {
  static final _numberedSong = RegExp(r'^(\d+)\s*[.)\-–—]\s+(.+)$');
  static final _dateInParens = RegExp(r'\((\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?\)');
  static final _dateLoose = RegExp(r'\b(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?\b');
  static final _keySuffix = RegExp(
    r'\s*\(([A-Ga-g][#b♯♭]?m?)\)\s*$',
  );
  static final _urlToken = RegExp(
    r'(https?://[^\s<>]+|(?:www\.)?(?:youtube\.com|youtu\.be)/[^\s<>]+)',
    caseSensitive: false,
  );
  static final _authorSeparator = RegExp(r'\s+[-–—]\s+');
  static final _ensaio = RegExp(r'ensaio', caseSensitive: false);
  static final _musicasPrefix = RegExp(
    r'^m[uú]sicas\s+para\s+(o\s+)?',
    caseSensitive: false,
  );
  static final _zeroWidth = RegExp(r'[\u200B-\u200D\uFEFF]');

  static CultoTemplate parse(String raw, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final cleaned = raw.replaceAll(_zeroWidth, '').replaceAll('\u00A0', ' ');
    final lines = cleaned.split(RegExp(r'\r?\n'));

    final songStarts = <int>[];
    for (var i = 0; i < lines.length; i++) {
      if (_numberedSong.hasMatch(lines[i].trim())) {
        songStarts.add(i);
      }
    }

    final headerEnd = songStarts.isEmpty ? lines.length : songStarts.first;
    final headerLines = [
      for (var i = 0; i < headerEnd; i++) lines[i].trim(),
    ].where((line) => line.isNotEmpty && !_ensaio.hasMatch(line)).toList();

    String? title;
    DateTime? date;
    if (headerLines.isNotEmpty) {
      title = _titleFrom(headerLines.first);
      date = _parseDate(headerLines.first, clock);
    }
    if (date == null) {
      for (final line in headerLines.skip(1)) {
        date = _parseDate(line, clock);
        if (date != null) break;
      }
    }

    final songs = <CultoTemplateSong>[];
    for (var index = 0; index < songStarts.length; index++) {
      final start = songStarts[index];
      final end =
          index + 1 < songStarts.length ? songStarts[index + 1] : lines.length;
      final song = _parseSong([
        for (var i = start; i < end; i++) lines[i],
      ]);
      if (song != null) songs.add(song);
    }

    return CultoTemplate(title: title, date: date, songs: songs);
  }

  static String? _titleFrom(String line) {
    var text = line.replaceAll(_dateInParens, '').trim();
    text = text.replaceAll(RegExp(r'\(\s*\)'), '').trim();
    text = text.replaceFirst(_musicasPrefix, '').trim();
    if (text.isEmpty) return null;
    return text[0].toUpperCase() + text.substring(1);
  }

  static DateTime? _parseDate(String line, DateTime now) {
    final match = _dateInParens.firstMatch(line) ?? _dateLoose.firstMatch(line);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    if (day == null || month == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    var year = now.year;
    final yearRaw = match.group(3);
    if (yearRaw != null) {
      year = int.parse(yearRaw);
      if (year < 100) year += 2000;
    }

    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  static CultoTemplateSong? _parseSong(List<String> block) {
    if (block.isEmpty) return null;
    final numbered = _numberedSong.firstMatch(block.first.trim());
    if (numbered == null) return null;

    var rest = numbered.group(2)!.trim();
    String? referenceUrl;

    final urlInLine = _urlToken.firstMatch(rest);
    if (urlInLine != null) {
      referenceUrl = _normalizeUrl(urlInLine.group(0)!);
      rest = rest.replaceRange(urlInLine.start, urlInLine.end, '').trim();
    }

    for (final line in block.skip(1)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || referenceUrl != null) continue;
      final urlMatch = _urlToken.firstMatch(trimmed);
      if (urlMatch != null) {
        referenceUrl = _normalizeUrl(urlMatch.group(0)!);
      }
    }

    String? musicalKey;
    final keyMatch = _keySuffix.firstMatch(rest);
    if (keyMatch != null) {
      musicalKey = _canonicalKey(keyMatch.group(1)!);
      rest = rest.substring(0, keyMatch.start).trim();
    }

    var title = rest;
    final authors = <String>[];
    final separators = _authorSeparator.allMatches(rest).toList();
    if (separators.isNotEmpty) {
      final last = separators.last;
      title = rest.substring(0, last.start).trim();
      final authorRaw = rest.substring(last.end).trim();
      if (authorRaw.isNotEmpty) {
        authors.addAll(
          authorRaw
              .split(',')
              .map((author) => author.trim())
              .where((author) => author.isNotEmpty),
        );
      }
    }

    if (title.isEmpty) return null;

    return CultoTemplateSong(
      title: title,
      authors: authors,
      musicalKey: musicalKey,
      referenceUrl: referenceUrl,
    );
  }

  static String? _normalizeUrl(String raw) {
    final stripped = raw.replaceAll(RegExp(r'[),.;]+$'), '');
    return UrlUtils.normalize(stripped);
  }

  static String? _canonicalKey(String raw) {
    final normalized = raw
        .trim()
        .replaceAll('♯', '#')
        .replaceAll('♭', 'b');
    for (final key in MusicalKeys.all) {
      if (key.toLowerCase() == normalized.toLowerCase()) return key;
    }
    return normalized;
  }
}
