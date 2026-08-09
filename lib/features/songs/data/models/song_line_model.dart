import '../../domain/entities/song_line.dart';

/// Maps [SongLine] to/from the jsonb shape stored in the `songs.lyrics`
/// column: `[{"type": "sessao", "content": "Refrão"}, ...]`.
abstract final class SongLineModel {
  static SongLine fromJson(Map<String, dynamic> json) {
    return SongLine(
      type: SongLineType.fromName(json['type'] as String? ?? 'extras'),
      content: json['content'] as String? ?? '',
    );
  }

  static Map<String, dynamic> toJson(SongLine line) {
    return {'type': line.type.name, 'content': line.content};
  }

  static List<SongLine> listFromJson(dynamic raw) {
    final list = raw as List? ?? const [];
    return list
        .map((item) => SongLineModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  static List<Map<String, dynamic>> listToJson(List<SongLine> lines) {
    return lines.map(SongLineModel.toJson).toList();
  }
}
