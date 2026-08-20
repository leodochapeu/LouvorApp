import '../../../../core/utils/date_formatters.dart';
import '../../domain/entities/culto.dart';

/// Maps between the `cultos` Supabase table rows and the [Culto] domain
/// entity. Keeping this conversion in one place means the rest of the app
/// never deals with raw JSON/column names.
abstract final class CultoModel {
  static Culto fromJson(Map<String, dynamic> json) {
    return Culto(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateFormatters.fromIsoDate(json['service_date'] as String),
      songIds: List<String>.from(json['song_ids'] as List? ?? const []),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static Map<String, dynamic> toInsertJson(CultoInput input) {
    return {
      'title': input.title,
      'service_date': DateFormatters.toIsoDate(input.date),
      'song_ids': input.songIds,
    };
  }
}
