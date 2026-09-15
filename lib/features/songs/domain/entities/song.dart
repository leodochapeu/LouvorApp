import 'package:equatable/equatable.dart';

import '../song_slug.dart';
import 'song_line.dart';

/// A worship song: title, authors, original key, lyrics+chords ("cifra"),
/// and an optional reference link (YouTube, etc.).
///
/// [currentKey] is not stored on the catalog song. It is overlaid when a
/// culto resolves its setlist — each service picks its own play key.
class Song extends Equatable {
  const Song({
    required this.id,
    required this.title,
    required this.authors,
    required this.originalKey,
    this.currentKey,
    required this.lines,
    this.referenceUrl,
    required this.slug,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final List<String> authors;

  /// "Tom original" — the key the song was originally written/recorded in.
  final String originalKey;

  /// "Tom alterado" for the current viewing context (a culto). `null` in
  /// the catalog, and when the culto uses the original key.
  final String? currentKey;

  /// Lyrics + chords ("cifra"), as an ordered list of tagged lines — see
  /// [SongLine] and `LyricsParser` for how raw pasted text becomes this.
  final List<SongLine> lines;

  /// Optional source link (YouTube, Spotify, church site, ...).
  final String? referenceUrl;

  /// Stable kebab-case identifier derived from title + authors. Unique.
  final String slug;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// The key that should be shown/used when playing the song: the altered
  /// key if one was set and non-empty, otherwise the original.
  String get effectiveKey {
    final altered = currentKey?.trim();
    if (altered != null && altered.isNotEmpty) return altered;
    return originalKey;
  }

  bool get hasAlteredKey {
    final altered = currentKey?.trim();
    return altered != null && altered.isNotEmpty && altered != originalKey;
  }

  /// True when there is a key to project scale degrees onto chord names.
  bool get hasPlayableKey => effectiveKey.trim().isNotEmpty;

  /// Overlay a culto's play key without mutating the catalog song.
  Song withPlayKey(String? playKey) {
    final key = playKey?.trim();
    final hasKey = key != null && key.isNotEmpty;
    return copyWith(
      currentKey: hasKey ? key : null,
      clearCurrentKey: !hasKey,
    );
  }

  String get authorsLabel => authors.isEmpty ? 'Autor desconhecido' : authors.join(', ');

  Song copyWith({
    String? id,
    String? title,
    List<String>? authors,
    String? originalKey,
    String? currentKey,
    bool clearCurrentKey = false,
    List<SongLine>? lines,
    String? referenceUrl,
    bool clearReferenceUrl = false,
    String? slug,
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
      referenceUrl:
          clearReferenceUrl ? null : (referenceUrl ?? this.referenceUrl),
      slug: slug ?? this.slug,
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
        referenceUrl,
        slug,
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
    required this.lines,
    this.referenceUrl,
  });

  final String title;
  final List<String> authors;
  final String originalKey;
  final List<SongLine> lines;
  final String? referenceUrl;

  String get slug => SongSlug.from(title: title, authors: authors);

  @override
  List<Object?> get props =>
      [title, authors, originalKey, lines, referenceUrl];
}
