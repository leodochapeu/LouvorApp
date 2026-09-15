import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/supabase_table_watch.dart';
import '../../domain/duplicate_culto_exception.dart';
import '../../domain/entities/culto.dart';
import '../../domain/repositories/culto_repository.dart';
import '../models/culto_model.dart';

/// [CultoRepository] backed by the `cultos` table in Supabase.
///
/// Reads start with a REST snapshot so the UI can render without waiting on
/// the websocket, then follow Supabase Realtime (`.stream`) so every
/// connected client — logged in or not — sees edits live. Writes are only
/// reachable from screens gated by the router's auth guard, but Row Level
/// Security in `supabase/schema.sql` is what actually enforces that
/// server-side.
class CultoRepositoryImpl implements CultoRepository {
  CultoRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const String _table = 'cultos';

  @override
  Stream<List<Culto>> watchCultos() {
    return watchSupabaseTable(
      fetchAll: _fetchAll,
      watchLive: () => _client
          .from(_table)
          .stream(primaryKey: ['id'])
          .order('service_date', ascending: false)
          .map(_mapRows),
    );
  }

  Future<List<Culto>> _fetchAll() async {
    final rows =
        await _client.from(_table).select().order('service_date', ascending: false);
    return _mapRows(rows);
  }

  List<Culto> _mapRows(List<Map<String, dynamic>> rows) {
    return [for (final row in rows) CultoModel.fromJson(row)];
  }

  @override
  Future<Culto> getById(String id) async {
    final row = await _client.from(_table).select().eq('id', id).single();
    return CultoModel.fromJson(row);
  }

  @override
  Future<Culto?> findBySlug(String slug) async {
    final row =
        await _client.from(_table).select().eq('slug', slug).maybeSingle();
    if (row == null) return null;
    return CultoModel.fromJson(row);
  }

  @override
  Future<Culto> create(CultoInput input) async {
    await _ensureSlugAvailable(input.slug);
    return _write(() async {
      final row = await _client
          .from(_table)
          .insert(CultoModel.toInsertJson(input))
          .select()
          .single();
      return CultoModel.fromJson(row);
    });
  }

  @override
  Future<Culto> update(String id, CultoInput input) async {
    await _ensureSlugAvailable(input.slug, excludingId: id);
    return _write(() async {
      final row = await _client
          .from(_table)
          .update(CultoModel.toInsertJson(input))
          .eq('id', id)
          .select()
          .single();
      return CultoModel.fromJson(row);
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
    throw const DuplicateCultoException();
  }

  Future<Culto> _write(Future<Culto> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const DuplicateCultoException();
      }
      rethrow;
    }
  }
}
