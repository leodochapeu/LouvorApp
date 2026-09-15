import 'package:equatable/equatable.dart';

import 'entities/song_line.dart';

/// Result of parsing the JSON cifra pasted into "Nova música".
class SongImport extends Equatable {
  const SongImport({
    required this.title,
    required this.authors,
    this.originalKey,
    this.currentKey,
    required this.lines,
  });

  final String title;
  final List<String> authors;

  /// "Tom original" from `musica.tom_original`.
  final String? originalKey;

  /// Play key from `musica.tom` when it differs from [originalKey]. Parsed
  /// for completeness; the song form does not save it — each culto stores
  /// its own tom alterado.
  final String? currentKey;

  /// Lyrics + chords already tagged with the form's line types, ready to
  /// convert back into the marked-up text of the song form.
  final List<SongLine> lines;

  @override
  List<Object?> get props => [title, authors, originalKey, currentKey, lines];
}

/// Thrown when the pasted JSON is missing required shape or cannot be read.
class SongImportException implements Exception {
  const SongImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
