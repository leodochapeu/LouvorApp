import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../providers/auth_providers.dart';

/// Email/password form used on [SignUpPage].
///
/// Calls [authControllerProvider] to create the account. If Supabase
/// returns a session immediately, [onSuccess] runs; otherwise a
/// "confirm your email" message is shown on the same screen.
class SignUpForm extends ConsumerStatefulWidget {
  const SignUpForm({super.key, this.onSuccess});

  final VoidCallback? onSuccess;

  @override
  ConsumerState<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _needsEmailConfirmation = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!success || !mounted) return;

    if (ref.read(isLoggedInProvider)) {
      widget.onSuccess?.call();
    } else {
      setState(() => _needsEmailConfirmation = true);
    }
  }

  String _friendlyError(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('already registered') ||
          message.contains('user already registered')) {
        return 'Este e-mail já está cadastrado';
      }
      if (message.contains('signups not allowed') ||
          message.contains('signup is disabled')) {
        return 'Cadastro desabilitado. Peça a um administrador.';
      }
      return error.message;
    }
    return 'Não foi possível cadastrar. Tente novamente.';
  }

  String? _confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme a senha';
    }
    if (value != _passwordController.text) {
      return 'As senhas não coincidem';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    if (_needsEmailConfirmation) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Confirme seu e-mail',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Enviamos um link para ${_emailController.text.trim()}. '
            'Abra-o para ativar a conta e depois entre pelo menu.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: _emailController,
            label: 'E-mail',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.email_outlined,
            validator: Validators.email,
          ),
          const SizedBox(height: AppSizes.md),
          AppTextField(
            controller: _passwordController,
            label: 'Senha',
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.lock_outline,
            validator: (v) => Validators.minLength(v, 6, field: 'A senha'),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          AppTextField(
            controller: _confirmPasswordController,
            label: 'Confirmar senha',
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_outline,
            onFieldSubmitted: (_) => _submit(),
            validator: _confirmPasswordValidator,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
          ),
          if (authState.hasError) ...[
            const SizedBox(height: 12),
            Text(
              _friendlyError(authState.error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSizes.lg),
          AppPrimaryButton(
            label: 'Cadastrar',
            isLoading: authState.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
