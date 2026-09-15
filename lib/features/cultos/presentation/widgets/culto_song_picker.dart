import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/musical_keys.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/inputs/app_search_field.dart';
import '../../../../core/widgets/layout/app_card.dart';
import '../../../songs/domain/entities/song.dart';
import '../../../songs/presentation/providers/song_providers.dart';
import '../../../songs/presentation/widgets/song_key_badge.dart';

/// Lets the user pick already-registered songs into an ordered setlist.
///
/// Selected songs can be reordered (the sequence of the culto), have a
/// per-culto play key, and be removed. A search field below lists catalog
/// songs that are not yet in the setlist.
class CultoSongPicker extends ConsumerStatefulWidget {
  const CultoSongPicker({
    super.key,
    required this.songIds,
    required this.songKeys,
    required this.onChanged,
  });

  final List<String> songIds;

  /// `songs.id` → tom alterado for this culto.
  final Map<String, String> songKeys;

  final void Function(List<String> songIds, Map<String, String> songKeys) onChanged;

  @override
  ConsumerState<CultoSongPicker> createState() => _CultoSongPickerState();
}

class _CultoSongPickerState extends ConsumerState<CultoSongPicker> {
  late final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, String> _keysKeeping(Iterable<String> ids) {
    return {
      for (final id in ids)
        if ((widget.songKeys[id] ?? '').trim().isNotEmpty)
          id: widget.songKeys[id]!.trim(),
    };
  }

  void _add(String id) {
    if (widget.songIds.contains(id)) return;
    widget.onChanged([...widget.songIds, id], _keysKeeping([...widget.songIds, id]));
  }

  void _remove(String id) {
    final ids = widget.songIds.where((songId) => songId != id).toList();
    widget.onChanged(ids, _keysKeeping(ids));
  }

  void _reorder(int oldIndex, int newIndex) {
    final ids = List<String>.of(widget.songIds);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = ids.removeAt(oldIndex);
    ids.insert(newIndex, item);
    widget.onChanged(ids, _keysKeeping(ids));
  }

  void _setKey(Song song, String? key) {
    final next = Map<String, String>.of(widget.songKeys);
    final trimmed = key?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == song.originalKey) {
      next.remove(song.id);
    } else {
      next[song.id] = trimmed;
    }
    widget.onChanged(widget.songIds, next);
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songsStreamProvider);
    final theme = Theme.of(context);

    return songsAsync.when(
      skipError: true,
      skipLoadingOnReload: true,
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
        child: AppLoadingIndicator(),
      ),
      error: (error, _) => AppErrorView.fromWatch(
        error: error,
        message: 'Não foi possível carregar as músicas.',
        onRetry: () => ref.invalidate(songsStreamProvider),
      ),
      data: (allSongs) {
        final byId = {for (final song in allSongs) song.id: song};
        final selected = [
          for (final id in widget.songIds)
            if (byId[id] != null) byId[id]!,
        ];

        final query = _query.trim().toLowerCase();
        final available = allSongs.where((song) {
          if (widget.songIds.contains(song.id)) return false;
          if (query.isEmpty) return true;
          return song.title.toLowerCase().contains(query) ||
              song.authors.any((author) => author.toLowerCase().contains(query));
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Músicas do culto', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Adicione músicas já cadastradas, escolha o tom deste culto e arraste para definir a ordem.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            if (selected.isEmpty)
              AppEmptyState(
                icon: Icons.queue_music_outlined,
                title: 'Nenhuma música neste culto',
                message: allSongs.isEmpty
                    ? 'Cadastre músicas primeiro para montar o culto.'
                    : 'Busque abaixo e toque para adicionar.',
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: selected.length,
                onReorder: _reorder,
                itemBuilder: (context, index) {
                  final song = selected[index];
                  return _SelectedSongTile(
                    key: ValueKey(song.id),
                    index: index,
                    song: song,
                    playKey: widget.songKeys[song.id] ?? song.originalKey,
                    onKeyChanged: (key) => _setKey(song, key),
                    onRemove: () => _remove(song.id),
                  );
                },
              ),
            const SizedBox(height: AppSizes.lg),
            AppSearchField(
              controller: _searchController,
              hint: 'Buscar música para adicionar',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: AppSizes.sm),
            if (allSongs.isEmpty)
              const SizedBox.shrink()
            else if (available.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                child: Text(
                  query.isEmpty
                      ? 'Todas as músicas já estão neste culto.'
                      : 'Nenhuma música encontrada.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: available.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSizes.xs),
                itemBuilder: (context, index) {
                  final song = available[index];
                  return _AvailableSongTile(
                    song: song,
                    onAdd: () => _add(song.id),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _SelectedSongTile extends StatelessWidget {
  const _SelectedSongTile({
    super.key,
    required this.index,
    required this.song,
    required this.playKey,
    required this.onKeyChanged,
    required this.onRemove,
  });

  final int index;
  final Song song;
  final String playKey;
  final ValueChanged<String> onKeyChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: Text(
                '${index + 1}',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.authorsLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _CultoKeySelector(
                  originalKey: song.originalKey,
                  value: playKey,
                  onChanged: onKeyChanged,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Remover',
            onPressed: onRemove,
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.drag_handle),
            ),
          ),
        ],
      ),
    );
  }
}

class _CultoKeySelector extends StatelessWidget {
  const _CultoKeySelector({
    required this.originalKey,
    required this.value,
    required this.onChanged,
  });

  final String originalKey;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = <String>[
      originalKey,
      ...MusicalKeys.all.where((key) => key != originalKey),
    ];
    final selected = keys.contains(value) ? value : originalKey;

    return Row(
      children: [
        Text(
          'Tom',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selected,
            isDense: true,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            items: [
              for (final key in keys)
                DropdownMenuItem(
                  value: key,
                  child: Text(key == originalKey ? '$key (original)' : key),
                ),
            ],
            onChanged: (key) {
              if (key != null) onChanged(key);
            },
          ),
        ),
      ],
    );
  }
}

class _AvailableSongTile extends StatelessWidget {
  const _AvailableSongTile({required this.song, required this.onAdd});

  final Song song;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onAdd,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.add_circle_outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.authorsLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SongKeyBadge(label: 'Tom original', musicalKey: song.originalKey),
        ],
      ),
    );
  }
}
