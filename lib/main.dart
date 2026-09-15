import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/config/missing_config_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

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
