import 'package:flutter_test/flutter_test.dart';
import 'package:louvor_app/features/songs/domain/entities/song.dart';
import 'package:louvor_app/features/songs/domain/song_catalog_lookup.dart';
import 'package:louvor_app/features/songs/domain/song_slug.dart';

void main() {
  Song song({
    required String id,
    required String title,
    List<String> authors = const [],
    String? referenceUrl,
  }) {
    return Song(
      id: id,
      title: title,
      authors: authors,
      originalKey: 'C',
      lines: const [],
      referenceUrl: referenceUrl,
      slug: SongSlug.from(title: title, authors: authors),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  final catalog = [
    song(
      id: '1',
      title: 'Tudo vai bem',
      authors: const ['Gabriel Rodrigues'],
      referenceUrl: 'https://youtu.be/nBBYAA7GWyw',
    ),
    song(
      id: '2',
      title: 'Outra música',
      authors: const ['Fulano'],
      referenceUrl: 'https://www.youtube.com/watch?v=wXLL6vo8Pxs',
    ),
  ];

  group('SongCatalogLookup', () {
    test('matches by title + authors slug', () {
      final match = SongCatalogLookup.match(
        catalog: catalog,
        title: 'Tudo vai bem',
        authors: const ['Gabriel Rodrigues'],
      );

      expect(match?.song.id, '1');
      expect(match?.by, SongMatchBy.slug);
    });

    test('matches by YouTube video id even when the URL shape differs', () {
      final match = SongCatalogLookup.match(
        catalog: catalog,
        title: 'Jeová Jireh',
        authors: const ['Aline Barros'],
        referenceUrl: 'https://youtu.be/wXLL6vo8Pxs?si=tracking',
      );

      expect(match?.song.id, '2');
      expect(match?.by, SongMatchBy.youtube);
    });

    test('prefers slug over youtube when both would match different songs', () {
      final match = SongCatalogLookup.match(
        catalog: catalog,
        title: 'Tudo vai bem',
        authors: const ['Gabriel Rodrigues'],
        referenceUrl: 'https://youtu.be/wXLL6vo8Pxs',
      );

      expect(match?.song.id, '1');
      expect(match?.by, SongMatchBy.slug);
    });

    test('ignores the song being edited', () {
      final match = SongCatalogLookup.match(
        catalog: catalog,
        title: 'Tudo vai bem',
        authors: const ['Gabriel Rodrigues'],
        excludingId: '1',
      );

      expect(match, isNull);
    });

    test('returns null when nothing matches', () {
      expect(
        SongCatalogLookup.find(
          catalog: catalog,
          title: 'Canção nova',
          authors: const ['Alguém'],
          referenceUrl: 'https://youtu.be/does-not-exist',
        ),
        isNull,
      );
    });
  });
}
