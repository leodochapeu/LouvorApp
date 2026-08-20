import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_providers.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(supabaseClientProvider));
});

/// Raw stream of auth state changes, kept alive for the whole app so the
/// router/drawer/etc. can react to sign in/out instantly.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// The currently signed-in user, or `null` when logged out.
///
/// Falls back to the repository's synchronous `currentUser` before the
/// stream has emitted its first event, avoiding a flash of "logged out" UI
/// on app start when a session is already persisted locally.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider).value;
  return authState?.session?.user ?? ref.watch(authRepositoryProvider).currentUser;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// Handles the sign in/out actions triggered from the UI (login form, drawer
/// logout button), exposing an [AsyncValue] so screens can show loading and
/// error states without extra state variables.
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithPassword(
            email: email,
            password: password,
          ),
    );
    state = result;
    return !result.hasError;
  }

  Future<bool> signUp({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signUp(
            email: email,
            password: password,
          ),
    );
    state = result;
    return !result.hasError;
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
