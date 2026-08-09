import 'package:flutter/material.dart';

import '../../domain/lyrics_parser.dart';
import 'song_lines_view.dart';

/// Live preview of how the pasted lyrics/chords text will be styled once
/// parsed, shown right below [LyricsField] so a person can confirm the
/// engine recognized each line (section/lyrics/chords/extra) correctly
/// before saving.
class LyricsPreview extends StatelessWidget {
  const LyricsPreview({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.text.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pré-visualização', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SongLinesView(lines: LyricsParser.parse(controller.text)),
            ),
          ],
        );
      },
    );
  }
}
