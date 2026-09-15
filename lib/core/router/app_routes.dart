/// Centralized route paths/names, so screens never hard-code path strings.
abstract final class AppRoutes {
  static const String songs = '/';
  static const String login = '/login';
  /// Hidden sign-up page — not linked from the drawer or login screen.
  static const String signUp = '/cadastro';
  static const String songNew = '/songs/new';
  static const String songDetail = '/songs/:slug';
  static const String songEdit = '/songs/:slug/edit';

  static const String cultos = '/cultos';
  static const String cultoNew = '/culto/new';
  static const String cultoDetail = '/culto/:slug';
  static const String cultoEdit = '/culto/:slug/edit';

  static String songDetailPath(String slug, {String? playKey}) {
    final path = '/songs/$slug';
    final tom = playKey?.trim();
    if (tom == null || tom.isEmpty) return path;
    return Uri(path: path, queryParameters: {'tom': tom}).toString();
  }
  static String songEditPath(String slug) => '/songs/$slug/edit';

  static String cultoDetailPath(String slug) => '/culto/$slug';
  static String cultoEditPath(String slug) => '/culto/$slug/edit';
}
