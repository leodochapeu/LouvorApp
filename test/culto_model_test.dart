import 'package:flutter_test/flutter_test.dart';
import 'package:louvor_app/features/cultos/data/models/culto_model.dart';
import 'package:louvor_app/features/cultos/domain/entities/culto.dart';

void main() {
  group('CultoModel', () {
    test('reads song_keys from a culto row', () {
      final culto = CultoModel.fromJson({
        'id': 'culto-1',
        'title': 'Culto da Família',
        'service_date': '2026-09-15',
        'song_ids': ['song-a', 'song-b'],
        'song_keys': {'song-a': 'A', 'song-b': '  '},
        'created_at': '2026-09-15T10:00:00.000Z',
        'updated_at': '2026-09-15T10:00:00.000Z',
      });

      expect(culto.songIds, ['song-a', 'song-b']);
      expect(culto.songKeys, {'song-a': 'A'});
      expect(culto.playKeyFor('song-a'), 'A');
      expect(culto.playKeyFor('song-b'), isNull);
    });

    test('parses song_keys from a JSON string', () {
      expect(
        CultoModel.songKeysFromJson('{"song-a": "A"}'),
        {'song-a': 'A'},
      );
    });

    test('treats a missing song_keys column as an empty map', () {
      final culto = CultoModel.fromJson({
        'id': 'culto-1',
        'title': 'Culto',
        'service_date': '2026-09-15',
        'song_ids': const [],
        'created_at': '2026-09-15T10:00:00.000Z',
        'updated_at': '2026-09-15T10:00:00.000Z',
      });

      expect(culto.songKeys, isEmpty);
    });

    test('writes song_keys on insert', () {
      final json = CultoModel.toInsertJson(
        CultoInput(
          title: 'Culto',
          date: DateTime(2026, 9, 15),
          songIds: const ['song-a'],
          songKeys: const {'song-a': 'Dm'},
        ),
      );

      expect(json['song_ids'], ['song-a']);
      expect(json['song_keys'], {'song-a': 'Dm'});
      expect(json['service_date'], '2026-09-15');
      expect(json.containsKey('slug'), isFalse);
    });
  });
}
