import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/song_line.dart';

/// Renders a song's tagged lines with per-type styling:
/// - [SongLineType.sessao]: bold, title-like, with extra spacing above.
/// - [SongLineType.letra]: italic.
/// - [SongLineType.cifra]: colored with the app's primary color.
/// - [SongLineType.extras]: gray (muted).
///
/// Blank lines are preserved as vertical spacing so the original structure
/// of the pasted cifra is kept.
class SongLinesView extends StatelessWidget {
  const SongLinesView({super.key, required this.lines});

  final List<SongLine> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty || lines.every((line) => line.content.isEmpty)) {
      return Text(
        'Sem letra/cifra cadastrada.',
        style: AppTextStyles.chordSheet(context),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final line in lines) _SongLineText(line: line)],
    );
  }
}

class _SongLineText extends StatelessWidget {
  const _SongLineText({required this.line});

  final SongLine line;

  @override
  Widget build(BuildContext context) {
    if (line.content.isEmpty) {
      return const SizedBox(height: 12);
    }

    final theme = Theme.of(context);
    final base = AppTextStyles.chordSheet(context);

    final style = switch (line.type) {
      SongLineType.sessao => base.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: (base.fontSize ?? 15) + 1,
          color: theme.colorScheme.onSurface,
        ),
      SongLineType.letra => base.copyWith(fontStyle: FontStyle.italic),
      SongLineType.cifra => base.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      SongLineType.extras => base.copyWith(color: theme.colorScheme.onSurfaceVariant),
    };

    return Padding(
      padding: line.type == SongLineType.sessao
          ? const EdgeInsets.only(top: 12, bottom: 2)
          : EdgeInsets.zero,
      child: SelectableText(line.content, style: style),
    );
  }
}
