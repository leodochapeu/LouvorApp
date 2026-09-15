import '../../../core/utils/date_formatters.dart';
import '../../songs/domain/song_slug.dart';

/// Kebab-case identifier from a culto's title and date, e.g.
/// `culto-da-familia-2026-09-15`.
abstract final class CultoSlug {
  static const fallback = 'culto';

  static String from({required String title, required DateTime date}) {
    final stem = SongSlug.kebab(title, fallback: fallback);
    return '$stem-${DateFormatters.toIsoDate(date)}';
  }
}
