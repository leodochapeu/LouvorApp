import 'package:equatable/equatable.dart';

import 'culto_slug.dart';

/// A worship service ("culto"): a named date with an ordered setlist of
/// already-registered songs.
class Culto extends Equatable {
  const Culto({
    required this.id,
    required this.title,
    required this.date,
    required this.songIds,
    this.songKeys = const {},
    required this.slug,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;

  /// Calendar day of the service (time is ignored).
  final DateTime date;

  /// Ordered song ids — the setlist. Full [Song]s are resolved in
  /// presentation from the songs list.
  final List<String> songIds;

  /// `songs.id` → tom alterado for this culto. Missing entries mean "play
  /// in the song's original key".
  final Map<String, String> songKeys;

  /// Stable kebab-case identifier from title + date. Unique.
  final String slug;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Play key stored on this culto for [songId], or `null` to use original.
  String? playKeyFor(String songId) {
    final key = songKeys[songId]?.trim();
    if (key == null || key.isEmpty) return null;
    return key;
  }

  int get songCount => songIds.length;

  String get songCountLabel {
    if (songCount == 1) return '1 música';
    return '$songCount músicas';
  }

  Culto copyWith({
    String? id,
    String? title,
    DateTime? date,
    List<String>? songIds,
    Map<String, String>? songKeys,
    String? slug,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Culto(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      songIds: songIds ?? this.songIds,
      songKeys: songKeys ?? this.songKeys,
      slug: slug ?? this.slug,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, date, songIds, songKeys, slug, createdAt, updatedAt];
}

/// Payload used to create or update a culto — no id/timestamps yet.
class CultoInput extends Equatable {
  const CultoInput({
    required this.title,
    required this.date,
    required this.songIds,
    this.songKeys = const {},
  });

  final String title;
  final DateTime date;
  final List<String> songIds;
  final Map<String, String> songKeys;

  String get slug => CultoSlug.from(title: title, date: date);

  @override
  List<Object?> get props => [title, date, songIds, songKeys];
}
