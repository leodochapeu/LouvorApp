import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import '../../../../core/config/supabase_providers.dart';
import '../../data/repositories/song_repository_impl.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';

final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepositoryImpl(ref.watch(supabaseClientProvider));
});

/// Live list of every song, straight from Supabase Realtime.
final songsStreamProvider = StreamProvider<List<Song>>((ref) {
  return ref.watch(songRepositoryProvider).watchSongs();
});

/// Current text typed into the search field on the songs list page.
final songSearchQueryProvider = StateProvider<String>((ref) => '');

/// [songsStreamProvider] filtered by [songSearchQueryProvider], matching
/// either the title or any of the authors (case-insensitive).
final filteredSongsProvider = Provider<AsyncValue<List<Song>>>((ref) {
  final songsAsync = ref.watch(songsStreamProvider);
  final query = ref.watch(songSearchQueryProvider).trim().toLowerCase();

  if (query.isEmpty) return songsAsync;

  return songsAsync.whenData((songs) {
    return songs.where((song) {
      final matchesTitle = song.title.toLowerCase().contains(query);
      final matchesAuthor =
          song.authors.any((author) => author.toLowerCase().contains(query));
      return matchesTitle || matchesAuthor;
    }).toList();
  });
});

/// A single song by id, sourced from the already-loaded live list when
/// available so opening a song from the list is instant; falls back to a
/// direct fetch (e.g. on a deep link straight to a song's detail page).
final songByIdProvider = FutureProvider.family<Song, String>((ref, id) async {
  final cached = ref.watch(songsStreamProvider).value;
  final match = cached?.where((song) => song.id == id).firstOrNull;
  if (match != null) return match;
  return ref.watch(songRepositoryProvider).getById(id);
});

/// Handles create/update/delete, exposing loading/error state for the form
/// and detail screens.
class SongMutationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Song?> save({required String? id, required SongInput input}) async {
    state = const AsyncLoading();
    final repo = ref.read(songRepositoryProvider);
    final result = await AsyncValue.guard(
      () => id == null ? repo.create(input) : repo.update(id, input),
    );
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    return result.value;
  }

  Future<bool> delete(String id) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => ref.read(songRepositoryProvider).delete(id));
    state = result;
    return !result.hasError;
  }
}

final songMutationControllerProvider =
    AsyncNotifierProvider<SongMutationController, void>(SongMutationController.new);
