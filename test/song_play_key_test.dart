import 'package:flutter_test/flutter_test.dart';
import 'package:louvor_app/features/songs/domain/entities/song.dart';

void main() {
  final catalogSong = Song(
    id: 'song-1',
    title: 'Canção',
    authors: const ['Autor'],
    originalKey: 'C',
    lines: const [],
    slug: 'cancao-autor',
    createdAt: DateTime.utc(2026, 9, 15),
    updatedAt: DateTime.utc(2026, 9, 15),
  );

  group('Song.withPlayKey', () {
    test('overlays a culto play key without changing the original', () {
      final played = catalogSong.withPlayKey('A');

      expect(played.originalKey, 'C');
      expect(played.currentKey, 'A');
      expect(played.effectiveKey, 'A');
      expect(played.hasAlteredKey, isTrue);
      expect(catalogSong.currentKey, isNull);
    });

    test('does not treat the original key as altered', () {
      final played = catalogSong.withPlayKey('C');

      expect(played.effectiveKey, 'C');
      expect(played.hasAlteredKey, isFalse);
    });

    test('clears a previous overlay', () {
      final played = catalogSong.withPlayKey('A').withPlayKey(null);

      expect(played.currentKey, isNull);
      expect(played.effectiveKey, 'C');
      expect(played.hasAlteredKey, isFalse);
    });
  });
}
