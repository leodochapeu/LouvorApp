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

/// Extra bottom inset so the last list item isn't hidden behind the options FAB.
const _fabClearance = 88.0;

/// Shows a culto's setlist. Cards mode matches the songs list; lyrics mode
/// stacks every song's formatted detail content, one after another.
///
/// Date, view-mode and font-size controls live in a bottom sheet opened
/// from a FAB, so the setlist can use the full screen.
class CultoDetailPage extends ConsumerWidget {
  const CultoDetailPage({super.key, required this.cultoId});

  final String cultoId;

  Future<void> _delete(BuildContext context, WidgetRef ref, Culto culto) async {
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
    if (!context.mounted) return;

    if (success) {
      context.go(AppRoutes.cultos);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir o culto.')),
      );
    }
  }

  void _openOptions(BuildContext context, DateTime date) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _CultoOptionsSheet(date: date),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cultoAsync = ref.watch(cultoByIdProvider(cultoId));
    final songsAsync = ref.watch(songsForCultoProvider(cultoId));
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final viewMode = ref.watch(cultoViewModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(cultoAsync.value?.title ?? 'Culto'),
        actions: [
          if (isLoggedIn && cultoAsync.hasValue) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () => context.push(AppRoutes.cultoEditPath(cultoId)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Excluir',
              onPressed: () => _delete(context, ref, cultoAsync.requireValue),
            ),
          ],
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: cultoAsync.hasValue
          ? FloatingActionButton(
              tooltip: 'Opções de visualização',
              onPressed: () => _openOptions(context, cultoAsync.requireValue.date),
              child: const Icon(Icons.tune),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
            child: cultoAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (error, _) => AppErrorView(
                message: 'Não foi possível carregar o culto.\n$error',
                onRetry: () => ref.invalidate(cultoByIdProvider(cultoId)),
              ),
              data: (_) => songsAsync.when(
                loading: () => const AppLoadingIndicator(),
                error: (error, _) => AppErrorView(
                  message: 'Não foi possível carregar as músicas.\n$error',
                  onRetry: () {
                    ref.invalidate(cultoByIdProvider(cultoId));
                    ref.invalidate(songsForCultoProvider(cultoId));
                  },
                ),
                data: (songs) => viewMode == CultoViewMode.cards
                    ? _CardsView(songs: songs)
                    : _LyricsView(
                        songs: songs,
                        fontSize: ref.watch(cultoLyricsFontSizeProvider),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CultoOptionsSheet extends ConsumerWidget {
  const _CultoOptionsSheet({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final viewMode = ref.watch(cultoViewModeProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Data', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSizes.xs),
            Text(DateFormatters.long(date), style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSizes.lg),
            Text('Visualização', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSizes.sm),
            SegmentedButton<CultoViewMode>(
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
              selected: {viewMode},
              onSelectionChanged: (selected) {
                ref.read(cultoViewModeProvider.notifier).state = selected.first;
              },
            ),
            if (viewMode == CultoViewMode.lyrics) ...[
              const SizedBox(height: AppSizes.lg),
              Text('Tamanho da letra', style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSizes.xs),
              const _LyricsFontControls(),
            ],
          ],
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
        AppSizes.md,
        AppSizes.md,
        _fabClearance,
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
        Text(
          '${fontSize.round()}',
          style: Theme.of(context).textTheme.titleMedium,
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
        AppSizes.md,
        AppSizes.md,
        _fabClearance,
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
