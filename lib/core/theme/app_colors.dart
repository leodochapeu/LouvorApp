import 'package:flutter/material.dart';

/// Brand seed color and a few semantic colors reused across the app.
///
/// The full [ColorScheme] is generated from [seed] in `app_theme.dart`;
/// widgets should read colors from `Theme.of(context).colorScheme` rather
/// than importing this file directly, except for the semantic accents below.
abstract final class AppColors {
  static const Color seed = Color(0xFF4F378B); // deep purple, worship/hymn feel

  static const Color success = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFBA1A1A);
  static const Color warning = Color(0xFFB25E00);
}
