import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/layout/app_card.dart';
import '../../domain/culto_template.dart';

/// Warns that some template songs are not in the catalog yet, and offers a
/// button to register each one before the culto can be saved.
class MissingTemplateSongsAlert extends StatelessWidget {
  const MissingTemplateSongsAlert({
    super.key,
    required this.songs,
    required this.onRegister,
  });

  final List<CultoTemplateSong> songs;
  final ValueChanged<CultoTemplateSong> onRegister;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countLabel = songs.length == 1
        ? '1 música ainda não está cadastrada'
        : '${songs.length} músicas ainda não estão cadastradas';

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      countLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      'Cadastre cada uma antes de criar o culto, para manter o repertório consistente.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          for (final song in songs) ...[
            _MissingSongTile(
              song: song,
              onRegister: () => onRegister(song),
            ),
            if (song != songs.last) const SizedBox(height: AppSizes.sm),
          ],
        ],
      ),
    );
  }
}

class _MissingSongTile extends StatelessWidget {
  const _MissingSongTile({required this.song, required this.onRegister});

  final CultoTemplateSong song;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  song.authorsLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (song.musicalKey != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Tom no culto: ${song.musicalKey}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          FilledButton.tonalIcon(
            onPressed: onRegister,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Cadastrar'),
          ),
        ],
      ),
    );
  }
}
