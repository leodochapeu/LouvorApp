/// Builds a stable kebab-case identifier from a song's title and authors.
///
/// Authors are sorted so the same names in a different order still produce
/// the same slug (and therefore collide as a duplicate).
abstract final class SongSlug {
  static const _from =
      'áàâãäéèêëíìîïóòôõöúùûüýÿçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÝŸÇÑ';
  static const _to =
      'aaaaaeeeeiiiiooooouuuuyycnAAAAAEEEEIIIIOOOOOUUUUYYCN';

  static const fallback = 'musica';

  static String from({required String title, required List<String> authors}) {
    final sortedAuthors = authors
        .map((author) => author.trim())
        .where((author) => author.isNotEmpty)
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final combined = [
      title.trim(),
      ...sortedAuthors,
    ].where((part) => part.isNotEmpty).join(' ');

    return kebab(combined);
  }

  static String kebab(String raw) {
    var value = raw.trim().toLowerCase();
    value = _stripDiacritics(value);
    value = value.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    value = value.replaceAll(RegExp(r'-{2,}'), '-');
    value = value.replaceAll(RegExp(r'^-+|-+$'), '');
    return value.isEmpty ? fallback : value;
  }

  static String _stripDiacritics(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      final index = _from.indexOf(char);
      buffer.write(index == -1 ? char : _to[index]);
    }
    return buffer.toString();
  }
}
