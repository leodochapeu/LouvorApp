import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/chips/app_chip.dart';
import '../../domain/entities/song.dart';
import 'song_key_badge.dart';
import 'song_lines_view.dart';

/// Full song body used on the song detail page and when a culto is shown
/// in "letra" mode (every song stacked, as if each detail page were open).
class SongDetailContent extends StatelessWidget {
  const SongDetailContent({super.key, required this.song, this.lyricsFontSize});

  final Song song;

  /// When set, scales the lyrics/chords (and nudges the title to match).
  final double? lyricsFontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = lyricsFontSize == null
        ? theme.textTheme.headlineSmall
        : theme.textTheme.headlineSmall?.copyWith(
            fontSize: (lyricsFontSize! * 1.4).clamp(18, 34),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(song.title, style: titleStyle),
        const SizedBox(height: AppSizes.sm),
        if (song.authors.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: song.authors
                .map((author) => AppChip(icon: Icons.person_outline, label: author))
                .toList(),
          ),
        const SizedBox(height: AppSizes.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SongKeyBadge(label: 'Tom original', musicalKey: song.originalKey),
            if (song.hasAlteredKey)
              SongKeyBadge(label: 'Tom alterado', musicalKey: song.currentKey),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        const Divider(),
        const SizedBox(height: AppSizes.md),
        SongLinesView(lines: song.lines, fontSize: lyricsFontSize),
      ],
    );
  }
}
