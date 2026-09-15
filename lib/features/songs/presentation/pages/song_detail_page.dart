import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/feedback/app_confirm_dialog.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/layout/app_drawer.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/song.dart';
import '../providers/song_providers.dart';
import '../widgets/song_detail_content.dart';

/// Shows a song's full lyrics + chords, along with its original key.
class SongDetailPage extends ConsumerWidget {
  const SongDetailPage({super.key, required this.songId});

  final String songId;

  Future<void> _delete(BuildContext context, WidgetRef ref, Song song) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Excluir música',
      message: 'Tem certeza que deseja excluir "${song.title}"? Essa ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      isDestructive: true,
    );
    if (!confirmed) return;

    final success = await ref.read(songMutationControllerProvider.notifier).delete(song.id);
    if (!context.mounted) return;

    if (success) {
      context.go(AppRoutes.songs);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir a música.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songAsync = ref.watch(songByIdProvider(songId));
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(songAsync.value?.title ?? 'Música'),
        actions: [
          if (isLoggedIn && songAsync.hasValue) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () => context.push(AppRoutes.songEditPath(songId)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Excluir',
              onPressed: () => _delete(context, ref, songAsync.requireValue),
            ),
          ],
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
            child: songAsync.when(
              skipError: true,
              skipLoadingOnReload: true,
              loading: () => const AppLoadingIndicator(),
              error: (error, _) => AppErrorView.fromWatch(
                error: error,
                message: 'Não foi possível carregar a música.',
                onRetry: () => ref.invalidate(songByIdProvider(songId)),
              ),
              data: (song) => SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SongDetailContent(song: song),
                    const SizedBox(height: AppSizes.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
