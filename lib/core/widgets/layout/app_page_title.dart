import 'package:flutter/material.dart';

/// Sets the browser tab title (and the document title crawlers read
/// after JS runs). WhatsApp previews still come from the server-side
/// Open Graph tags in `/api/share`.
class AppPageTitle extends StatelessWidget {
  const AppPageTitle({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Title(
      title: title,
      color: Theme.of(context).colorScheme.primary,
      child: child,
    );
  }
}
