import '../utils/date_formatters.dart';

/// Copy used in the browser tab title and in WhatsApp/Open Graph previews.
abstract final class SharePreview {
  static const siteName = 'Louvor App';
  static const homeDescription =
      'Cifras, letras e setlists de louvor para o culto.';

  static String pageTitle(String page) => '$page · $siteName';

  static String songTitle(String title) => pageTitle(title);

  static String songDescription({
    required String title,
    required List<String> authors,
    String? originalKey,
  }) {
    final namedAuthors = authors
        .map((author) => author.trim())
        .where((author) => author.isNotEmpty)
        .toList();
    final buffer = StringBuffer('Cifra e letra de $title');
    if (namedAuthors.isNotEmpty) {
      buffer.write(', de ${namedAuthors.join(', ')}');
    }
    final key = originalKey?.trim();
    if (key != null && key.isNotEmpty) {
      buffer.write('. Tom original: $key');
    }
    buffer.write('.');
    return buffer.toString();
  }

  static String cultoTitle(String title) => pageTitle(title);

  static String cultoDescription({
    required String title,
    required DateTime date,
    required int songCount,
  }) {
    final countLabel = songCount == 1 ? '1 música' : '$songCount músicas';
    return 'Setlist de $title · ${DateFormatters.long(date)} · $countLabel.';
  }

  static String cultosListDescription() =>
      'Setlists dos cultos, com cifras e letras.';

  static String songsListDescription() => homeDescription;
}
