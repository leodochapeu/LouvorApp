import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import '../../../../core/config/supabase_providers.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../songs/domain/entities/song.dart';
import '../../../songs/presentation/providers/song_providers.dart';
import '../../data/repositories/culto_repository_impl.dart';
import '../../domain/entities/culto.dart';
import '../../domain/repositories/culto_repository.dart';

final cultoRepositoryProvider = Provider<CultoRepository>((ref) {
  return CultoRepositoryImpl(ref.watch(supabaseClientProvider));
});

/// Live list of every culto, straight from Supabase Realtime.
final cultosStreamProvider = StreamProvider<List<Culto>>((ref) {
  return ref.watch(cultoRepositoryProvider).watchCultos();
});

/// Current text typed into the search field on the cultos list page.
final cultoSearchQueryProvider = StateProvider<String>((ref) => '');

/// Font size for the culto "Letra" view. Shared across cultos in the session
/// so bumping the type on one service carries over to the next.
abstract final class CultoLyricsFontSize {
  static const double min = 12;
  static const double max = 28;
  static const double step = 2;
  static const double initial = 15;
}

final cultoLyricsFontSizeProvider = StateProvider<double>(
  (ref) => CultoLyricsFontSize.initial,
);

/// [cultosStreamProvider] filtered by [cultoSearchQueryProvider], matching
/// the title or the formatted date (case-insensitive).
final filteredCultosProvider = Provider<AsyncValue<List<Culto>>>((ref) {
  final cultosAsync = ref.watch(cultosStreamProvider);
  final query = ref.watch(cultoSearchQueryProvider).trim().toLowerCase();

  if (query.isEmpty) return cultosAsync;

  return cultosAsync.whenData((cultos) {
    return cultos.where((culto) {
      final matchesTitle = culto.title.toLowerCase().contains(query);
      final matchesDate = DateFormatters.short(culto.date).contains(query) ||
          DateFormatters.long(culto.date).toLowerCase().contains(query);
      return matchesTitle || matchesDate;
    }).toList();
  });
});

/// A single culto by id, sourced from the already-loaded live list when
/// available so opening a culto from the list is instant; falls back to a
/// direct fetch (e.g. on a deep link straight to a culto's detail page).
final cultoByIdProvider = FutureProvider.family<Culto, String>((ref, id) async {
  final cached = ref.watch(cultosStreamProvider).value;
  final match = cached?.where((culto) => culto.id == id).firstOrNull;
  if (match != null) return match;
  return ref.watch(cultoRepositoryProvider).getById(id);
});

/// Resolves a culto's setlist into full [Song]s, in setlist order.
///
/// Songs that were deleted after being added to the culto are skipped.
final songsForCultoProvider = Provider.family<AsyncValue<List<Song>>, String>((ref, cultoId) {
  final cultoAsync = ref.watch(cultoByIdProvider(cultoId));
  final songsAsync = ref.watch(songsStreamProvider);

  if (cultoAsync.isLoading || songsAsync.isLoading) {
    return const AsyncLoading();
  }
  if (cultoAsync.hasError) {
    return AsyncError(cultoAsync.error!, cultoAsync.stackTrace ?? StackTrace.empty);
  }
  if (songsAsync.hasError) {
    return AsyncError(songsAsync.error!, songsAsync.stackTrace ?? StackTrace.empty);
  }

  final culto = cultoAsync.requireValue;
  final byId = {for (final song in songsAsync.requireValue) song.id: song};
  return AsyncData([
    for (final id in culto.songIds)
      if (byId[id] != null) byId[id]!,
  ]);
});

/// Handles create/update/delete, exposing loading/error state for the form
/// and detail screens.
class CultoMutationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Culto?> save({required String? id, required CultoInput input}) async {
    state = const AsyncLoading();
    final repo = ref.read(cultoRepositoryProvider);
    final result = await AsyncValue.guard(
      () => id == null ? repo.create(input) : repo.update(id, input),
    );
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    return result.value;
  }

  Future<bool> delete(String id) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => ref.read(cultoRepositoryProvider).delete(id));
    state = result;
    return !result.hasError;
  }
}

final cultoMutationControllerProvider =
    AsyncNotifierProvider<CultoMutationController, void>(CultoMutationController.new);
