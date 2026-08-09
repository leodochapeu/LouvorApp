import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/config/missing_config_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // `.env` isn't committed (see .gitignore) — `.env.example` documents the
  // expected keys. Missing the file entirely is tolerated so a fresh clone
  // can still boot into the "not configured" screen below.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env yet — Env.isSupabaseConfigured will be false and we show
    // MissingConfigApp instead of crashing.
  }

  if (!Env.isSupabaseConfigured) {
    runApp(const MissingConfigApp());
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    // `publishableKey` is Supabase's current name for what used to be
    // called the "anon" key; the "anon public" key from your project's API
    // settings works here too.
    publishableKey: Env.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: LouvorApp()));
}
