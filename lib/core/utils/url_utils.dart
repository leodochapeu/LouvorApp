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
    return _isYouTubeHost(uri.host);
  }

  /// Video id shared by `youtu.be/ID`, `watch?v=ID`, `/embed/ID`, `/shorts/ID`
  /// and `/live/ID`. Tracking params (`si`, `t`, …) are ignored so two
  /// different URL shapes of the same video still match.
  static String? youtubeVideoId(String? raw) {
    final uri = tryParseHttp(raw);
    if (uri == null || !_isYouTubeHost(uri.host)) return null;

    final host = uri.host.toLowerCase();
    if (host == 'youtu.be' || host == 'www.youtu.be') {
      if (uri.pathSegments.isEmpty) return null;
      final id = uri.pathSegments.first.trim();
      return id.isEmpty ? null : id;
    }

    final fromQuery = uri.queryParameters['v']?.trim();
    if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;

    const prefixes = {'embed', 'shorts', 'live', 'v'};
    if (uri.pathSegments.length >= 2 &&
        prefixes.contains(uri.pathSegments.first.toLowerCase())) {
      final id = uri.pathSegments[1].trim();
      return id.isEmpty ? null : id;
    }

    return null;
  }

  static bool _isYouTubeHost(String host) {
    final normalized = host.toLowerCase();
    return _youtubeHosts.contains(normalized) ||
        normalized.endsWith('.youtube.com');
  }
}
