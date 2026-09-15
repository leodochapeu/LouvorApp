import 'package:flutter/material.dart';

import '../../domain/entities/song.dart';

/// Original + optional altered key badges. When the song is being played
/// in another key (a culto's tom), the original is muted and "Tom alterado"
/// is highlighted.
class SongKeyBadges extends StatelessWidget {
  const SongKeyBadges({
    super.key,
    required this.song,
    this.compact = false,
  });

  final Song song;

  /// Catalog cards use a short "Tom" label when there is no altered key.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!song.hasAlteredKey) {
      return SongKeyBadge(
        label: compact ? 'Tom' : 'Tom original',
        musicalKey: song.originalKey,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: compact ? WrapAlignment.end : WrapAlignment.start,
      children: [
        SongKeyBadge(
          label: 'Tom original',
          musicalKey: song.originalKey,
          enabled: false,
        ),
        SongKeyBadge(
          label: 'Tom alterado',
          musicalKey: song.currentKey,
        ),
      ],
    );
  }
}

/// Small badge showing a musical key, e.g. "Tom: C".
class SongKeyBadge extends StatelessWidget {
  const SongKeyBadge({
    super.key,
    required this.label,
    this.musicalKey,
    this.enabled = true,
  });

  final String label;
  final String? musicalKey;

  /// When false, the badge is muted (used for "Tom original" once an
  /// altered key is the one actually being played).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (musicalKey == null) return const SizedBox.shrink();

    final background = enabled
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = enabled
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $musicalKey',
        style: theme.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
