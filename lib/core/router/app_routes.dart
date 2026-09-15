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
  static const String cultoNew = '/cultos/new';
  static const String cultoDetail = '/cultos/:slug';
  static const String cultoEdit = '/cultos/:slug/edit';

  static String songDetailPath(String slug) => '/songs/$slug';
  static String songEditPath(String slug) => '/songs/$slug/edit';

  static String cultoDetailPath(String slug) => '/cultos/$slug';
  static String cultoEditPath(String slug) => '/cultos/$slug/edit';
}
