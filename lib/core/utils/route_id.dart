/// Helpers for public route params, which may be a slug or a legacy UUID.
abstract final class RouteId {
  static final _fullUuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static final _uuidAtEnd = RegExp(
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool isUuid(String value) => _fullUuid.hasMatch(value);

  /// UUID at the end of a slug such as `culto-de-domingo-30-08-<uuid>`.
  static String? uuidAtEnd(String value) =>
      _uuidAtEnd.firstMatch(value.trim())?.group(0);
}
