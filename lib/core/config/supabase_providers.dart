import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared handle to the Supabase client, initialized once in `main.dart` via
/// `Supabase.initialize`. Every feature repository reads it from here
/// instead of touching `Supabase.instance` directly, which keeps the data
/// layer easy to fake in tests.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
