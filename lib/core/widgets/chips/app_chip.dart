import 'package:flutter/material.dart';

/// Small pill used to display a single piece of metadata (an author name, a
/// musical key, a tag...). Purely presentational — no selection state.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.onDeleted,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = color ?? theme.colorScheme.secondaryContainer;
    final foreground = color == null
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onSurface;

    return Chip(
      avatar: icon == null ? null : Icon(icon, size: 16, color: foreground),
      label: Text(label, style: TextStyle(color: foreground)),
      backgroundColor: background,
      onDeleted: onDeleted,
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
