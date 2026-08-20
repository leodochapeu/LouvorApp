import 'package:equatable/equatable.dart';

import 'song_line.dart';

/// A worship song: title, authors, its original key, an optional key it's
/// currently being played in, and the lyrics+chords ("cifra") content.
class Song extends Equatable {
  const Song({
    required this.id,
    required this.title,
    required this.authors,
    required this.originalKey,
    this.currentKey,
    required this.lines,
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

  /// Lyrics + chords ("cifra"), as an ordered list of tagged lines — see
  /// [SongLine] and `LyricsParser` for how raw pasted text becomes this.
  final List<SongLine> lines;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// The key that should be shown/used when playing the song: the altered
  /// key if one was set and non-empty, otherwise the original.
  String get effectiveKey {
    final altered = currentKey?.trim();
    if (altered != null && altered.isNotEmpty) return altered;
    return originalKey;
  }

  bool get hasAlteredKey => currentKey != null && currentKey != originalKey;

  /// True when there is a key to project scale degrees onto chord names.
  bool get hasPlayableKey => effectiveKey.trim().isNotEmpty;

  String get authorsLabel => authors.isEmpty ? 'Autor desconhecido' : authors.join(', ');

  Song copyWith({
    String? id,
    String? title,
    List<String>? authors,
    String? originalKey,
    String? currentKey,
    bool clearCurrentKey = false,
    List<SongLine>? lines,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      originalKey: originalKey ?? this.originalKey,
      currentKey: clearCurrentKey ? null : (currentKey ?? this.currentKey),
      lines: lines ?? this.lines,
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
        lines,
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
    required this.lines,
  });

  final String title;
  final List<String> authors;
  final String originalKey;
  final String? currentKey;
  final List<SongLine> lines;

  @override
  List<Object?> get props => [title, authors, originalKey, currentKey, lines];
}
