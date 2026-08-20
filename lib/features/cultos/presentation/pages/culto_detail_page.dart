import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/buttons/app_icon_button.dart';
import '../../../../core/widgets/feedback/app_confirm_dialog.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/layout/app_drawer.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../songs/domain/entities/song.dart';
import '../../../songs/presentation/widgets/song_card.dart';
import '../../../songs/presentation/widgets/song_detail_content.dart';
import '../../domain/entities/culto.dart';
import '../providers/culto_providers.dart';

enum CultoViewMode { cards, lyrics }

/// Shows a culto's setlist. Cards mode matches the songs list; lyrics mode
/// stacks every song's formatted detail content, one after another.
class CultoDetailPage extends ConsumerStatefulWidget {
  const CultoDetailPage({super.key, required this.cultoId});

  final String cultoId;

  @override
  ConsumerState<CultoDetailPage> createState() => _CultoDetailPageState();
}

class _CultoDetailPageState extends ConsumerState<CultoDetailPage> {
  CultoViewMode _viewMode = CultoViewMode.cards;

  Future<void> _delete(Culto culto) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Excluir culto',
      message:
          'Tem certeza que deseja excluir "${culto.title}"? As músicas cadastradas não serão apagadas.',
      confirmLabel: 'Excluir',
      isDestructive: true,
    );
    if (!confirmed) return;

    final success = await ref.read(cultoMutationControllerProvider.notifier).delete(culto.id);
    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.cultos);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir o culto.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cultoAsync = ref.watch(cultoByIdProvider(widget.cultoId));
    final songsAsync = ref.watch(songsForCultoProvider(widget.cultoId));
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(cultoAsync.value?.title ?? 'Culto'),
        actions: [
          if (isLoggedIn && cultoAsync.hasValue) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () => context.push(AppRoutes.cultoEditPath(widget.cultoId)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Excluir',
              onPressed: () => _delete(cultoAsync.requireValue),
            ),
          ],
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
            child: cultoAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (error, _) => AppErrorView(
                message: 'Não foi possível carregar o culto.\n$error',
                onRetry: () => ref.invalidate(cultoByIdProvider(widget.cultoId)),
              ),
              data: (culto) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.md,
                      AppSizes.md,
                      AppSizes.md,
                      AppSizes.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormatters.long(culto.date),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<CultoViewMode>(
                            segments: const [
                              ButtonSegment(
                                value: CultoViewMode.cards,
                                icon: Icon(Icons.view_agenda_outlined),
                                label: Text('Cards'),
                              ),
                              ButtonSegment(
                                value: CultoViewMode.lyrics,
                                icon: Icon(Icons.notes_outlined),
                                label: Text('Letra'),
                              ),
                            ],
                            selected: {_viewMode},
                            onSelectionChanged: (selected) {
                              setState(() => _viewMode = selected.first);
                            },
                          ),
                        ),
                        if (_viewMode == CultoViewMode.lyrics) ...[
                          const SizedBox(height: AppSizes.sm),
                          const _LyricsFontControls(),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: songsAsync.when(
                      loading: () => const AppLoadingIndicator(),
                      error: (error, _) => AppErrorView(
                        message: 'Não foi possível carregar as músicas.\n$error',
                        onRetry: () {
                          ref.invalidate(cultoByIdProvider(widget.cultoId));
                          ref.invalidate(songsForCultoProvider(widget.cultoId));
                        },
                      ),
                      data: (songs) => _viewMode == CultoViewMode.cards
                          ? _CardsView(songs: songs)
                          : _LyricsView(
                              songs: songs,
                              fontSize: ref.watch(cultoLyricsFontSizeProvider),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardsView extends StatelessWidget {
  const _CardsView({required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const AppEmptyState(
        icon: Icons.queue_music_outlined,
        title: 'Nenhuma música neste culto',
        message: 'As músicas podem ter sido excluídas. Edite o culto para adicionar outras.',
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
        final theme = Theme.of(context);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: Text(
                '${index + 1}',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: SongCard(
                song: song,
                onTap: () => context.push(AppRoutes.songDetailPath(song.id)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LyricsFontControls extends ConsumerWidget {
  const _LyricsFontControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(cultoLyricsFontSizeProvider);
    final canDecrease = fontSize > CultoLyricsFontSize.min;
    final canIncrease = fontSize < CultoLyricsFontSize.max;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AppIconButton(
          icon: Icons.text_decrease,
          tooltip: 'Diminuir fonte',
          onPressed: canDecrease
              ? () {
                  ref.read(cultoLyricsFontSizeProvider.notifier).state =
                      (fontSize - CultoLyricsFontSize.step).clamp(
                    CultoLyricsFontSize.min,
                    CultoLyricsFontSize.max,
                  );
                }
              : null,
        ),
        AppIconButton(
          icon: Icons.text_increase,
          tooltip: 'Aumentar fonte',
          onPressed: canIncrease
              ? () {
                  ref.read(cultoLyricsFontSizeProvider.notifier).state =
                      (fontSize + CultoLyricsFontSize.step).clamp(
                    CultoLyricsFontSize.min,
                    CultoLyricsFontSize.max,
                  );
                }
              : null,
        ),
      ],
    );
  }
}

class _LyricsView extends StatelessWidget {
  const _LyricsView({required this.songs, required this.fontSize});

  final List<Song> songs;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const AppEmptyState(
        icon: Icons.queue_music_outlined,
        title: 'Nenhuma música neste culto',
        message: 'As músicas podem ter sido excluídas. Edite o culto para adicionar outras.',
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
      separatorBuilder: (_, _) => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
        child: Divider(),
      ),
      itemBuilder: (context, index) => SongDetailContent(
        song: songs[index],
        lyricsFontSize: fontSize,
      ),
    );
  }
}
