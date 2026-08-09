import '../entities/song.dart';

/// Contract for reading/writing songs, implemented against Supabase in
/// `data/repositories/song_repository_impl.dart`.
abstract class SongRepository {
  /// Live list of all songs, ordered by title. Emits again whenever a song
  /// is created, updated or deleted (Supabase Realtime).
  Stream<List<Song>> watchSongs();

  Future<Song> getById(String id);

  Future<Song> create(SongInput input);

  Future<Song> update(String id, SongInput input);

  Future<void> delete(String id);
}
