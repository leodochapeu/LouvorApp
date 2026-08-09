import '../../domain/entities/song.dart';
import 'song_line_model.dart';

/// Maps between the `songs` Supabase table rows and the [Song] domain
/// entity. Keeping this conversion in one place means the rest of the app
/// never deals with raw JSON/column names.
abstract final class SongModel {
  static Song fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      authors: List<String>.from(json['authors'] as List? ?? const []),
      originalKey: json['original_key'] as String,
      currentKey: json['current_key'] as String?,
      lines: SongLineModel.listFromJson(json['lyrics']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static Map<String, dynamic> toInsertJson(SongInput input) {
    return {
      'title': input.title,
      'authors': input.authors,
      'original_key': input.originalKey,
      'current_key': input.currentKey,
      'lyrics': SongLineModel.listToJson(input.lines),
    };
  }
}
