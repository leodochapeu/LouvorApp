import '../../domain/entities/song.dart';
import '../../domain/song_slug.dart';
import 'song_line_model.dart';

/// Maps between the `songs` Supabase table rows and the [Song] domain
/// entity. Keeping this conversion in one place means the rest of the app
/// never deals with raw JSON/column names.
abstract final class SongModel {
  static Song fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String;
    final authors = List<String>.from(json['authors'] as List? ?? const []);
    return Song(
      id: json['id'] as String,
      title: title,
      authors: authors,
      originalKey: json['original_key'] as String,
      lines: SongLineModel.listFromJson(json['lyrics']),
      referenceUrl: json['reference_url'] as String?,
      slug: (json['slug'] as String?)?.trim().isNotEmpty == true
          ? json['slug'] as String
          : SongSlug.from(title: title, authors: authors),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static Map<String, dynamic> toInsertJson(SongInput input) {
    return {
      'title': input.title,
      'authors': input.authors,
      'original_key': input.originalKey,
      'lyrics': SongLineModel.listToJson(input.lines),
      'reference_url': input.referenceUrl,
      'slug': input.slug,
    };
  }
}
