import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/branding/app_logo.dart';
import '../widgets/login_form.dart';

/// Standalone login screen, reachable from the drawer. Sign-up is a
/// separate hidden route ([AppRoutes.signUp]) and is not linked from here.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  /// After a successful sign-in, go back to the page the user was
  /// redirected from (if the router sent them here via a guarded route),
  /// otherwise pop the drawer-opened login screen or fall back to home.
  void _onLoginSuccess(BuildContext context) {
    final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
    if (redirect != null) {
      context.go(redirect);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.songs);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppLogo(size: 72)),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Entre para editar as músicas',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'A listagem e as letras/cifras continuam públicas mesmo sem login.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.xl),
                  LoginForm(
                    onSuccess: () => _onLoginSuccess(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
