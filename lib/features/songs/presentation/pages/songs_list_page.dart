import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/inputs/app_search_field.dart';
import '../../../../core/widgets/layout/app_drawer.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/song_providers.dart';
import '../widgets/song_card.dart';

/// Home page: the public songs list with search. This is the app's initial
/// route — no login page is shown up front.
class SongsListPage extends ConsumerStatefulWidget {
  const SongsListPage({super.key});

  @override
  ConsumerState<SongsListPage> createState() => _SongsListPageState();
}

class _SongsListPageState extends ConsumerState<SongsListPage> {
  late final _searchController = TextEditingController(
    text: ref.read(songSearchQueryProvider),
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(filteredSongsProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final hasQuery = ref.watch(songSearchQueryProvider).isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Músicas')),
      drawer: const AppDrawer(),
      floatingActionButton: isLoggedIn
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.songNew),
              icon: const Icon(Icons.add),
              label: const Text('Nova música'),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.md,
                    AppSizes.md,
                    AppSizes.md,
                    AppSizes.sm,
                  ),
                  child: AppSearchField(
                    controller: _searchController,
                    onChanged: (value) =>
                        ref.read(songSearchQueryProvider.notifier).state = value,
                  ),
                ),
                Expanded(
                  child: songsAsync.when(
                    skipError: true,
                    skipLoadingOnReload: true,
                    loading: () => const AppLoadingIndicator(),
                    error: (error, _) => AppErrorView.fromWatch(
                      error: error,
                      message: 'Não foi possível carregar as músicas.',
                      onRetry: () => ref.invalidate(songsStreamProvider),
                    ),
                    data: (songs) {
                      if (songs.isEmpty) {
                        return AppEmptyState(
                          title: hasQuery
                              ? 'Nenhuma música encontrada'
                              : 'Nenhuma música cadastrada',
                          message: hasQuery
                              ? 'Tente buscar por outro nome ou autor.'
                              : (isLoggedIn
                                  ? 'Toque em "Nova música" para cadastrar a primeira.'
                                  : 'Faça login para cadastrar músicas.'),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSizes.md,
                          AppSizes.sm,
                          AppSizes.md,
                          AppSizes.xxl,
                        ),
                        itemCount: songs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          return SongCard(
                            song: song,
                            onTap: () => context.push(AppRoutes.songDetailPath(song.id)),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
