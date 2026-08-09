import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/songs/presentation/pages/song_detail_page.dart';
import '../../features/songs/presentation/pages/song_form_page.dart';
import '../../features/songs/presentation/pages/songs_list_page.dart';
import 'app_routes.dart';

/// Turns a [Stream] into a [Listenable] so [GoRouter] can re-run its
/// `redirect` callback whenever the Supabase auth state changes (e.g. the
/// user logs in from the drawer and a route guard should re-evaluate).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Paths that require an authenticated user (creating/editing a song).
/// Reading songs and their lyrics/chords stays public.
bool _requiresAuth(String location) {
  return location == AppRoutes.songNew || location.endsWith('/edit');
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: AppRoutes.songs,
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) {
      final isLoggedIn = ref.read(isLoggedInProvider);
      final location = state.matchedLocation;

      if (_requiresAuth(location) && !isLoggedIn) {
        return Uri(
          path: AppRoutes.login,
          queryParameters: {'redirect': location},
        ).toString();
      }

      if (location == AppRoutes.login && isLoggedIn) {
        return state.uri.queryParameters['redirect'] ?? AppRoutes.songs;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.songs,
        builder: (context, state) => const SongsListPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        // Declared before `/songs/:id` so "new" is never matched as an id.
        path: AppRoutes.songNew,
        builder: (context, state) => const SongFormPage(),
      ),
      GoRoute(
        path: AppRoutes.songDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SongDetailPage(songId: id);
        },
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SongFormPage(songId: id);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: Center(child: Text('Nada em ${state.uri.path}')),
    ),
  );
});
