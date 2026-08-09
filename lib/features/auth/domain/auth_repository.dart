import 'package:supabase_flutter/supabase_flutter.dart';

/// Contract for authentication, kept separate from the Supabase
/// implementation so the presentation layer never depends on the SDK
/// directly.
abstract class AuthRepository {
  /// Emits every time the auth session changes (sign in, sign out, token
  /// refresh...).
  Stream<AuthState> get authStateChanges;

  /// The currently signed-in user, if any.
  User? get currentUser;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
