import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Builds the public URL of a page and copies it for WhatsApp/sharing.
abstract final class ShareLink {
  static String forPath(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return '${Uri.base.origin}$normalized';
  }

  static Future<void> copy(
    BuildContext context, {
    required String url,
  }) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copiado. Cole no WhatsApp para compartilhar.'),
      ),
    );
  }
}
