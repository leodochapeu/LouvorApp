import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/share/share_link.dart';
import '../../../../core/share/share_preview.dart';
import '../../../../core/widgets/feedback/app_confirm_dialog.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/layout/app_drawer.dart';
import '../../../../core/widgets/layout/app_page_title.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/song.dart';
import '../providers/song_providers.dart';
import '../widgets/song_detail_content.dart';

/// Shows a song's full lyrics + chords, along with its original key.
class SongDetailPage extends ConsumerWidget {
  const SongDetailPage({super.key, required this.slug});

  final String slug;

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

  Future<void> _share(BuildContext context, Song song) {
    return ShareLink.copy(
      context,
      url: ShareLink.forPath(AppRoutes.songDetailPath(song.slug)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songAsync = ref.watch(songByIdProvider(slug));
    final isLoggedIn = ref.watch(isLoggedInProvider);

    ref.listen(songByIdProvider(slug), (previous, next) {
      final song = next.value;
      if (song == null || song.slug == slug) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.replace(AppRoutes.songDetailPath(song.slug));
        }
      });
    });

    final pageTitle = songAsync.value == null
        ? SharePreview.pageTitle('Música')
        : SharePreview.songTitle(songAsync.value!.title);

    return AppPageTitle(
      title: pageTitle,
      child: Scaffold(
        appBar: AppBar(
          title: Text(songAsync.value?.title ?? 'Música'),
          actions: [
            if (songAsync.hasValue)
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Compartilhar',
                onPressed: () => _share(context, songAsync.requireValue),
              ),
            if (isLoggedIn && songAsync.hasValue) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
                onPressed: () =>
                    context.push(AppRoutes.songEditPath(songAsync.requireValue.slug)),
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
                  onRetry: () => ref.invalidate(songByIdProvider(slug)),
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
      ),
    );
  }
}
