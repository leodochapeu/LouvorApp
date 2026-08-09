import 'package:equatable/equatable.dart';

/// A worship song: title, authors, its original key, an optional key it's
/// currently being played in, and the lyrics+chords ("cifra") text.
class Song extends Equatable {
  const Song({
    required this.id,
    required this.title,
    required this.authors,
    required this.originalKey,
    this.currentKey,
    required this.lyrics,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final List<String> authors;

  /// "Tom original" — the key the song was originally written/recorded in.
  final String originalKey;

  /// "Tom alterado" — set only when the song is being played in a different
  /// key than [originalKey].
  final String? currentKey;

  /// Full lyrics with chords inlined (the "cifra"), stored as plain text.
  final String lyrics;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// The key that should be shown/used when playing the song: the altered
  /// key if one was set, otherwise the original.
  String get effectiveKey => currentKey ?? originalKey;

  bool get hasAlteredKey => currentKey != null && currentKey != originalKey;

  String get authorsLabel => authors.isEmpty ? 'Autor desconhecido' : authors.join(', ');

  Song copyWith({
    String? id,
    String? title,
    List<String>? authors,
    String? originalKey,
    String? currentKey,
    bool clearCurrentKey = false,
    String? lyrics,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      originalKey: originalKey ?? this.originalKey,
      currentKey: clearCurrentKey ? null : (currentKey ?? this.currentKey),
      lyrics: lyrics ?? this.lyrics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        authors,
        originalKey,
        currentKey,
        lyrics,
        createdAt,
        updatedAt,
      ];
}

/// Payload used to create or update a song — intentionally separate from
/// [Song] since it has no id/timestamps yet.
class SongInput extends Equatable {
  const SongInput({
    required this.title,
    required this.authors,
    required this.originalKey,
    this.currentKey,
    required this.lyrics,
  });

  final String title;
  final List<String> authors;
  final String originalKey;
  final String? currentKey;
  final String lyrics;

  @override
  List<Object?> get props => [title, authors, originalKey, currentKey, lyrics];
}
