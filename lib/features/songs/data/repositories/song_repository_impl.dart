import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/duplicate_song_exception.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../models/song_model.dart';

/// [SongRepository] backed by the `songs` table in Supabase.
///
/// Reads use Supabase Realtime (`.stream`) so every connected client -
/// logged in or not - sees edits live. Writes are only reachable from
/// screens gated by the router's auth guard, but Row Level Security in
/// `supabase/schema.sql` is what actually enforces that server-side.
class SongRepositoryImpl implements SongRepository {
  SongRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const String _table = 'songs';

  @override
  Stream<List<Song>> watchSongs() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('title')
        .map((rows) => rows.map(SongModel.fromJson).toList());
  }

  @override
  Future<Song> getById(String id) async {
    final row = await _client.from(_table).select().eq('id', id).single();
    return SongModel.fromJson(row);
  }

  @override
  Future<Song?> findBySlug(String slug) async {
    final row =
        await _client.from(_table).select().eq('slug', slug).maybeSingle();
    if (row == null) return null;
    return SongModel.fromJson(row);
  }

  @override
  Future<Song> create(SongInput input) async {
    await _ensureSlugAvailable(input.slug);
    return _write(() async {
      final row = await _client
          .from(_table)
          .insert(SongModel.toInsertJson(input))
          .select()
          .single();
      return SongModel.fromJson(row);
    });
  }

  @override
  Future<Song> update(String id, SongInput input) async {
    await _ensureSlugAvailable(input.slug, excludingId: id);
    return _write(() async {
      final row = await _client
          .from(_table)
          .update(SongModel.toInsertJson(input))
          .eq('id', id)
          .select()
          .single();
      return SongModel.fromJson(row);
    });
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  Future<void> _ensureSlugAvailable(String slug, {String? excludingId}) async {
    final existing = await findBySlug(slug);
    if (existing == null) return;
    if (excludingId != null && existing.id == excludingId) return;
    throw const DuplicateSongException();
  }

  Future<Song> _write(Future<Song> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const DuplicateSongException();
      }
      rethrow;
    }
  }
}
