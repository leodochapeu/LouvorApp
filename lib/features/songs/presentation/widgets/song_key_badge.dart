import 'package:flutter/material.dart';

/// Small badge showing a musical key, e.g. "Tom: C".
class SongKeyBadge extends StatelessWidget {
  const SongKeyBadge({super.key, required this.label, this.musicalKey});

  final String label;
  final String? musicalKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (musicalKey == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $musicalKey',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
