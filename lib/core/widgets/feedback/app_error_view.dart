import 'package:flutter/material.dart';

import '../../data/supabase_table_watch.dart';
import '../buttons/app_primary_button.dart';
import 'app_loading_indicator.dart';

/// Standard "something went wrong" state with an optional retry action.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  /// Realtime subscribe timeouts are not real load failures — keep showing
  /// the spinner until data arrives (or a genuine error does).
  static Widget fromWatch({
    required Object error,
    required String message,
    VoidCallback? onRetry,
  }) {
    if (isTransientRealtimeError(error)) {
      return const AppLoadingIndicator();
    }
    return AppErrorView(
      message: '$message\n$error',
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              AppPrimaryButton(
                label: 'Tentar novamente',
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
