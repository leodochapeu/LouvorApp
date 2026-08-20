import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography helpers shared across the app.
///
/// [chordSheet] uses a monospaced font so chord letters stay aligned above
/// the lyrics, which is the whole point of a "cifra" text block.
abstract final class AppTextStyles {
  /// Builds the Inter-based [TextTheme] for [colorScheme].
  ///
  /// `GoogleFonts.interTextTheme` swaps in the Inter font family but doesn't
  /// reliably carry over [base]'s colors for every style (Material's own
  /// `Typography` leaves some roles, like `titleLarge`, without an explicit
  /// color and expects it to come from whatever widget renders them — that
  /// works for `AppBar`, which reasserts a color itself, but leaves plain
  /// `Text(style: textTheme.titleLarge)` calls elsewhere nearly invisible).
  /// `.apply(...)` forces every style to a concrete color so the theme is
  /// safe to use directly anywhere.
  static TextTheme textTheme(TextTheme base, ColorScheme colorScheme) {
    return GoogleFonts.interTextTheme(base).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
  }

  static const double chordSheetSize = 15;

  static TextStyle chordSheet(BuildContext context, {double? fontSize}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize ?? chordSheetSize,
        height: 1.6,
        color: Theme.of(context).colorScheme.onSurface,
      );
}
