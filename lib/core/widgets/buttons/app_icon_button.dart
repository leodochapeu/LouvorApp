import 'package:flutter/material.dart';

/// Thin wrapper around [IconButton] that enforces a tooltip, so every
/// icon-only action in the app stays accessible.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      color: color,
      onPressed: onPressed,
    );
  }
}
