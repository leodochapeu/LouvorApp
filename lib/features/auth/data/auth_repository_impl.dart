import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_repository.dart';

/// [AuthRepository] backed by Supabase Auth.
///
/// Sign-up lives on a hidden route (`/cadastro`) that is never linked from
/// the UI — see `supabase/schema.sql` for the expected Auth settings.
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
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
