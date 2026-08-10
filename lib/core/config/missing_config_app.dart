import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shown instead of the real app when the `SUPABASE_URL`/`SUPABASE_ANON_KEY`
/// compile-time defines weren't provided, so `flutter run`/`flutter build`
/// gives a clear next step instead of a crash. See `.env.json.example` and
/// `supabase/schema.sql`.
class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.settings_outlined, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Supabase ainda não configurado',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Copie .env.json.example para .env.json\n'
                      '2. Preencha SUPABASE_URL e SUPABASE_ANON_KEY com os dados do seu projeto\n'
                      '3. Rode o script supabase/schema.sql no SQL editor do Supabase\n'
                      '4. Rode com: flutter run -d chrome --dart-define-from-file=.env.json',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
