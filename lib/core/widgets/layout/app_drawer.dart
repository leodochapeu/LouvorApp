import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../router/app_routes.dart';
import '../branding/app_logo.dart';

/// App-wide navigation drawer.
///
/// Holds the login/logout entry point, since the app has no dedicated login
/// page in the main flow — auth only gates editing, so it lives here instead
/// of the home screen.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isLoggedIn = user != null;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              child: Row(
                children: [
                  const AppLogo(size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Louvor App',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          isLoggedIn ? user.email ?? 'Logado' : 'Visitante',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.queue_music_outlined),
              title: const Text('Músicas'),
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.songs);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_note_outlined),
              title: const Text('Cultos'),
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.cultos);
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            if (isLoggedIn)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(authControllerProvider.notifier).signOut();
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Entrar'),
                subtitle: const Text('Necessário para editar músicas e cultos'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(AppRoutes.login);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
