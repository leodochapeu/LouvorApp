import 'package:flutter/material.dart';

import '../../constants/app_sizes.dart';

/// Standard page scaffold: app bar + optional drawer/FAB + content that is
/// centered and width-capped on large (web) screens.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.drawer,
    this.floatingActionButton,
    this.centerContent = true,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    final content = centerContent
        ? Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
              child: body,
            ),
          )
        : body;

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: content),
    );
  }
}
