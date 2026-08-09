/// Centralized route paths/names, so screens never hard-code path strings.
abstract final class AppRoutes {
  static const String songs = '/';
  static const String login = '/login';
  static const String songNew = '/songs/new';
  static const String songDetail = '/songs/:id';
  static const String songEdit = '/songs/:id/edit';

  static String songDetailPath(String id) => '/songs/$id';
  static String songEditPath(String id) => '/songs/$id/edit';
}
