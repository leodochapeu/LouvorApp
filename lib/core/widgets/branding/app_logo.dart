import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';

/// Brand mark for headers and auth screens.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        AppAssets.logo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        semanticLabel: 'Louvor App',
      ),
    );
  }
}
