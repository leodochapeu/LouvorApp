import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/chips/app_chip.dart';
import '../../domain/degree_to_chord.dart';
import '../../domain/entities/song.dart';
import '../providers/song_providers.dart';
import 'chord_display_mode_button.dart';
import 'song_key_badge.dart';
import 'song_lines_view.dart';
import 'song_reference_link_button.dart';

/// Full song body used on the song detail page and when a culto is shown
/// in "letra" mode (every song stacked, as if each detail page were open).
class SongDetailContent extends ConsumerWidget {
  const SongDetailContent({super.key, required this.song, this.lyricsFontSize});

  final Song song;

  /// When set, scales the lyrics/chords (and nudges the title to match).
  final double? lyricsFontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final titleStyle = lyricsFontSize == null
        ? theme.textTheme.headlineSmall
        : theme.textTheme.headlineSmall?.copyWith(
            fontSize: (lyricsFontSize! * 1.4).clamp(18, 34),
          );

    final showAsChords = song.hasPlayableKey &&
        ref.watch(chordDisplayModeProvider) == ChordDisplayMode.names;
    final lines = showAsChords
        ? DegreeToChord.convertLines(song.lines, song.effectiveKey)
        : song.lines;

    final referenceUrl = song.referenceUrl?.trim();
    final hasReferenceLink = referenceUrl != null && referenceUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text(song.title, style: titleStyle)),
            if (hasReferenceLink) ...[
              const SizedBox(width: AppSizes.sm),
              SongReferenceLinkButton(url: referenceUrl),
            ],
          ],
        ),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SongKeyBadge(
                    label: 'Tom original',
                    musicalKey: song.originalKey,
                    enabled: !song.hasAlteredKey,
                  ),
                  if (song.hasAlteredKey)
                    SongKeyBadge(label: 'Tom alterado', musicalKey: song.currentKey),
                ],
              ),
            ),
            if (song.hasPlayableKey) const ChordDisplayModeButton(),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        const Divider(),
        const SizedBox(height: AppSizes.md),
        SongLinesView(lines: lines, fontSize: lyricsFontSize),
      ],
    );
  }
}
