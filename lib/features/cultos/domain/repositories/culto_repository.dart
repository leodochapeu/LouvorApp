import '../entities/culto.dart';

/// Contract for reading/writing cultos, implemented against Supabase in
/// `data/repositories/culto_repository_impl.dart`.
abstract class CultoRepository {
  /// Live list of all cultos, newest date first. Emits again whenever a
  /// culto is created, updated or deleted (Supabase Realtime).
  Stream<List<Culto>> watchCultos();

  Future<Culto> getById(String id);

  Future<Culto?> findBySlug(String slug);

  Future<Culto> create(CultoInput input);

  Future<Culto> update(String id, CultoInput input);

  Future<void> delete(String id);
}
