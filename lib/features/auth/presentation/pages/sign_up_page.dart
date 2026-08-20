import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/app_routes.dart';
import '../widgets/sign_up_form.dart';

/// Hidden sign-up screen, reachable only by typing [AppRoutes.signUp].
/// It is never linked from the drawer or the login page.
class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  void _onSignUpSuccess(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.songs);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
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
                  Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Crie sua conta',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'Depois do cadastro você poderá editar as músicas.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.xl),
                  SignUpForm(
                    onSuccess: () => _onSignUpSuccess(context),
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
