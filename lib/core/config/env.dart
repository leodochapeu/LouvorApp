import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place to read environment configuration.
///
/// Values come from the `.env` file (see `.env.example`), loaded once in
/// `main.dart` via `flutter_dotenv` before the app starts.
abstract final class Env {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL']?.trim() ?? '';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

  /// Whether the required Supabase credentials were provided.
  ///
  /// Kept intentionally simple so the app can boot into a friendly
  /// "not configured yet" screen instead of crashing when someone runs the
  /// project before creating their own Supabase instance.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
