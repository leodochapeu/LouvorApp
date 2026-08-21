import 'package:equatable/equatable.dart';

/// How a single line of a song's content should be styled/rendered.
enum SongLineType {
  /// A section title, e.g. "Introdução", "Refrão", "Ponte".
  sessao,

  /// A line of lyrics.
  letra,

  /// A line of chords, either note names ("C Am F G") or scale degrees
  /// ("1 6 4 5").
  cifra,

  /// Anything else: repeat markers, performance notes, unrecognized text.
  extras;

  static SongLineType fromName(String value) {
    return SongLineType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => SongLineType.extras,
    );
  }
}

/// One line of a song's body, tagged with how it should be styled.
///
/// Songs are stored as an ordered list of these (see `SongLineModel` for the
/// JSON shape) instead of a single block of text, so the UI can render
/// sections, lyrics, chords and free-form notes differently.
class SongLine extends Equatable {
  const SongLine({
    required this.type,
    required this.content,
    this.suffix = '',
  });

  final SongLineType type;
  final String content;

  /// Annotation that followed the line's markup, e.g. `(²*)` after
  /// `|| 4 1 5 ||`. Kept out of [content] so degree→chord conversion does
  /// not rewrite it.
  final String suffix;

  @override
  List<Object?> get props => [type, content, suffix];
}
