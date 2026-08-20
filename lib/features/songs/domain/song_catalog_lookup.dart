import 'package:collection/collection.dart';

import '../../../core/utils/url_utils.dart';
import 'entities/song.dart';
import 'song_slug.dart';

enum SongMatchBy { slug, youtube }

class SongCatalogMatch {
  const SongCatalogMatch({required this.song, required this.by});

  final Song song;
  final SongMatchBy by;
}

/// Finds a catalog song by the same rules used when checking duplicates:
/// title+authors slug first, then the YouTube video id of the reference link.
abstract final class SongCatalogLookup {
  static Song? find({
    required List<Song> catalog,
    required String title,
    required List<String> authors,
    String? referenceUrl,
    String? excludingId,
  }) {
    return match(
      catalog: catalog,
      title: title,
      authors: authors,
      referenceUrl: referenceUrl,
      excludingId: excludingId,
    )?.song;
  }

  static SongCatalogMatch? match({
    required List<Song> catalog,
    required String title,
    required List<String> authors,
    String? referenceUrl,
    String? excludingId,
  }) {
    final songs = excludingId == null
        ? catalog
        : catalog.where((song) => song.id != excludingId);

    final slug = SongSlug.from(title: title, authors: authors);
    final bySlug = songs.firstWhereOrNull((song) => song.slug == slug);
    if (bySlug != null) {
      return SongCatalogMatch(song: bySlug, by: SongMatchBy.slug);
    }

    final videoId = UrlUtils.youtubeVideoId(referenceUrl);
    if (videoId == null) return null;

    final byYoutube = songs.firstWhereOrNull(
      (song) => UrlUtils.youtubeVideoId(song.referenceUrl) == videoId,
    );
    if (byYoutube == null) return null;
    return SongCatalogMatch(song: byYoutube, by: SongMatchBy.youtube);
  }
}
