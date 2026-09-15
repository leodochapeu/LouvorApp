import '../../../core/utils/route_id.dart';
import '../../songs/domain/song_slug.dart';

/// Public identifier for a culto URL, e.g.
/// `culto-de-domingo-30-08-173f5f23-ff0e-4142-96b8-eeaabac8d642`.
abstract final class CultoSlug {
  static const fallback = 'culto';

  static String from({
    required String title,
    required DateTime date,
    required String id,
  }) {
    final stem = SongSlug.kebab(title, fallback: fallback);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$stem-$day-$month-$id';
  }

  /// UUID at the end of a culto slug, or [slug] itself when it is a UUID.
  static String? idFrom(String slug) => RouteId.uuidAtEnd(slug);
}
