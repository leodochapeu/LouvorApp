import '../../../../core/utils/date_formatters.dart';
import '../../domain/culto_slug.dart';
import '../../domain/entities/culto.dart';

/// Maps between the `cultos` Supabase table rows and the [Culto] domain
/// entity. Keeping this conversion in one place means the rest of the app
/// never deals with raw JSON/column names.
abstract final class CultoModel {
  static Culto fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String;
    final date = DateFormatters.fromIsoDate(json['service_date'] as String);
    return Culto(
      id: json['id'] as String,
      title: title,
      date: date,
      songIds: List<String>.from(json['song_ids'] as List? ?? const []),
      songKeys: songKeysFromJson(json['song_keys']),
      slug: (json['slug'] as String?)?.trim().isNotEmpty == true
          ? json['slug'] as String
          : CultoSlug.from(title: title, date: date),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static Map<String, dynamic> toInsertJson(CultoInput input) {
    return {
      'title': input.title,
      'service_date': DateFormatters.toIsoDate(input.date),
      'song_ids': input.songIds,
      'song_keys': input.songKeys,
      'slug': input.slug,
    };
  }

  /// `{"song-uuid": "A"}` — empty/invalid values are dropped.
  static Map<String, String> songKeysFromJson(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        if (_nonEmpty(entry.value) != null) entry.key.toString(): _nonEmpty(entry.value)!,
    };
  }

  static String? _nonEmpty(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
