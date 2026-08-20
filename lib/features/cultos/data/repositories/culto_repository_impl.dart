import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/culto.dart';
import '../../domain/repositories/culto_repository.dart';
import '../models/culto_model.dart';

/// [CultoRepository] backed by the `cultos` table in Supabase.
///
/// Reads use Supabase Realtime (`.stream`) so every connected client —
/// logged in or not — sees edits live. Writes are only reachable from
/// screens gated by the router's auth guard, but Row Level Security in
/// `supabase/schema.sql` is what actually enforces that server-side.
class CultoRepositoryImpl implements CultoRepository {
  CultoRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const String _table = 'cultos';

  @override
  Stream<List<Culto>> watchCultos() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('service_date', ascending: false)
        .map((rows) => rows.map(CultoModel.fromJson).toList());
  }

  @override
  Future<Culto> getById(String id) async {
    final row = await _client.from(_table).select().eq('id', id).single();
    return CultoModel.fromJson(row);
  }

  @override
  Future<Culto> create(CultoInput input) async {
    final row = await _client
        .from(_table)
        .insert(CultoModel.toInsertJson(input))
        .select()
        .single();
    return CultoModel.fromJson(row);
  }

  @override
  Future<Culto> update(String id, CultoInput input) async {
    final row = await _client
        .from(_table)
        .update(CultoModel.toInsertJson(input))
        .eq('id', id)
        .select()
        .single();
    return CultoModel.fromJson(row);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
