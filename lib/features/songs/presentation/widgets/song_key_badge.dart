import 'package:flutter/material.dart';

/// Small badge showing a musical key, e.g. "Tom: C".
class SongKeyBadge extends StatelessWidget {
  const SongKeyBadge({
    super.key,
    required this.label,
    this.musicalKey,
    this.enabled = true,
  });

  final String label;
  final String? musicalKey;

  /// When false, the badge is muted (used for "Tom original" once an
  /// altered key is the one actually being played).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (musicalKey == null) return const SizedBox.shrink();

    final background = enabled
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = enabled
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $musicalKey',
        style: theme.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
