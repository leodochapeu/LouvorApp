import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_repository.dart';

/// [AuthRepository] backed by Supabase Auth.
///
/// User accounts are created manually in the Supabase dashboard (see
/// `supabase/schema.sql` header comment) — there is no public sign-up flow
/// in this app, only sign in/out.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
