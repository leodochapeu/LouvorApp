import 'package:equatable/equatable.dart';

/// Result of parsing the WhatsApp-style setlist pasted into "Novo culto".
class CultoTemplate extends Equatable {
  const CultoTemplate({
    this.title,
    this.date,
    required this.songs,
  });

  final String? title;
  final DateTime? date;
  final List<CultoTemplateSong> songs;

  bool get isEmpty =>
      (title == null || title!.trim().isEmpty) && date == null && songs.isEmpty;

  @override
  List<Object?> get props => [title, date, songs];
}

/// One numbered entry from the template: title, author(s), optional key and
/// optional reference link (usually YouTube).
class CultoTemplateSong extends Equatable {
  const CultoTemplateSong({
    required this.title,
    required this.authors,
    this.musicalKey,
    this.referenceUrl,
  });

  final String title;
  final List<String> authors;

  /// Key written next to the song in the template (the "tom alterado" of
  /// that culto). Parsed so we can show it, but not applied yet.
  final String? musicalKey;

  final String? referenceUrl;

  String get authorsLabel =>
      authors.isEmpty ? 'Autor não informado' : authors.join(', ');

  @override
  List<Object?> get props => [title, authors, musicalKey, referenceUrl];
}
