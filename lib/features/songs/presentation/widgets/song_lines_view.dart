import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/song_line.dart';
import '../../domain/lyrics_parser.dart';

/// Renders a song's tagged lines with per-type styling:
/// - [SongLineType.sessao]: bold, title-like, with extra spacing above.
/// - [SongLineType.letra]: italic.
/// - [SongLineType.cifra]: colored with the app's primary color.
/// - [SongLineType.extras]: gray (muted).
/// - Inline `_"texto"_` (any type): italic.
/// - Inline `~texto~` (any type): strikethrough.
///
/// Blank lines are preserved as vertical spacing so the original structure
/// of the pasted cifra is kept.
class SongLinesView extends StatelessWidget {
  const SongLinesView({super.key, required this.lines, this.fontSize});

  final List<SongLine> lines;

  /// Overrides the default chord-sheet size. Used by the culto "Letra"
  /// view so the congregation can bump the type up or down.
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty ||
        lines.every((line) => line.content.isEmpty && line.suffix.isEmpty)) {
      return Text(
        'Sem letra/cifra cadastrada.',
        style: AppTextStyles.chordSheet(context, fontSize: fontSize),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines) _SongLineText(line: line, fontSize: fontSize),
      ],
    );
  }
}

class _SongLineText extends StatelessWidget {
  const _SongLineText({required this.line, this.fontSize});

  final SongLine line;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final resolvedSize = fontSize ?? AppTextStyles.chordSheetSize;

    if (line.content.isEmpty && line.suffix.isEmpty) {
      return SizedBox(height: resolvedSize * 0.8);
    }

    final theme = Theme.of(context);
    final base = AppTextStyles.chordSheet(context, fontSize: resolvedSize);

    final style = switch (line.type) {
      SongLineType.sessao => base.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: resolvedSize + 1,
          color: theme.colorScheme.onSurface,
        ),
      SongLineType.letra => base.copyWith(fontStyle: FontStyle.italic),
      SongLineType.cifra => base.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      SongLineType.extras => base.copyWith(color: theme.colorScheme.onSurfaceVariant),
    };
    final suffixStyle = base.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Padding(
      padding: line.type == SongLineType.sessao
          ? const EdgeInsets.only(top: 12, bottom: 2)
          : EdgeInsets.zero,
      child: SelectableText.rich(
        TextSpan(
          children: [
            ..._inlineSpans(line.content, style),
            if (line.suffix.isNotEmpty) ...[
              TextSpan(text: ' ', style: style),
              ..._inlineSpans(line.suffix, suffixStyle),
            ],
          ],
        ),
      ),
    );
  }

  static List<InlineSpan> _inlineSpans(String text, TextStyle style) {
    return [
      for (final run in LyricsParser.inlineRuns(text))
        TextSpan(
          text: run.text,
          style: style.copyWith(
            fontStyle: run.italic ? FontStyle.italic : style.fontStyle,
            decoration: run.strikethrough
                ? TextDecoration.lineThrough
                : style.decoration,
            decorationColor:
                run.strikethrough ? style.color : style.decorationColor,
          ),
        ),
    ];
  }
}
