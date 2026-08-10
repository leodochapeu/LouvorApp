/// Central place to read environment configuration.
///
/// Values are compiled in at build time via `--dart-define` (or
/// `--dart-define-from-file=.env.json` for local dev — see
/// `.env.json.example`), **not** loaded from a bundled asset. A file-based
/// asset would need to exist inside the CI/deploy environment (Vercel,
/// Firebase Hosting, ...) at build time, but `.env*` files are gitignored on
/// purpose since they hold secrets — that combination breaks `flutter build
/// web` there. Compile-time defines have no such requirement: if they're not
/// provided, they simply default to an empty string below.
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Whether the required Supabase credentials were provided.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
