/// Small collection of reusable form validators.
///
/// Each function follows the `FormFieldValidator<String>` signature so it
/// can be passed straight into `AppTextField(validator: ...)`.
abstract final class Validators {
  static String? required(String? value, {String field = 'Campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field é obrigatório';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o e-mail';
    }
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value.trim())) {
      return 'E-mail inválido';
    }
    return null;
  }

  static String? minLength(String? value, int length, {String field = 'Campo'}) {
    if (value == null || value.trim().length < length) {
      return '$field deve ter no mínimo $length caracteres';
    }
    return null;
  }

  /// Combines multiple validators, returning the first error found.
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
