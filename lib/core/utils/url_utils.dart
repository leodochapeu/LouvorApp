/// Helpers for optional HTTP(S) links stored on songs (YouTube, etc.).
abstract final class UrlUtils {
  static final _schemePrefix = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:');

  static const _youtubeHosts = {
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'music.youtube.com',
    'youtu.be',
    'www.youtu.be',
    'youtube-nocookie.com',
    'www.youtube-nocookie.com',
  };

  /// Trims [raw] and adds `https://` when the scheme is missing. Empty input
  /// becomes `null` so the database can store a nullable column.
  static String? normalize(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (_schemePrefix.hasMatch(trimmed)) return trimmed;
    return 'https://$trimmed';
  }

  /// Parses an HTTP(S) URL, or `null` if the value is empty/invalid.
  static Uri? tryParseHttp(String? raw) {
    final normalized = normalize(raw);
    if (normalized == null) return null;
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    // Reject "https://not a url" and other hosts that aren't a hostname.
    if (!RegExp(r'^[a-zA-Z0-9.-]+$').hasMatch(uri.host)) return null;
    if (!uri.host.contains('.')) return null;
    return uri;
  }

  static bool isYouTube(String? raw) {
    final uri = tryParseHttp(raw);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return _youtubeHosts.contains(host) || host.endsWith('.youtube.com');
  }
}
