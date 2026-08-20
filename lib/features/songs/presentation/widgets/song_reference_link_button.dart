import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/url_utils.dart';

/// Opens the song's reference URL in a new browser tab / external app.
///
/// YouTube links get a branded button; anything else is a simple link icon.
class SongReferenceLinkButton extends StatelessWidget {
  const SongReferenceLinkButton({super.key, required this.url});

  final String url;

  Future<void> _open(BuildContext context) async {
    final uri = UrlUtils.tryParseHttp(url);
    if (uri == null) {
      _showError(context);
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!launched && context.mounted) {
        _showError(context);
      }
    } catch (_) {
      if (context.mounted) {
        _showError(context);
      }
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir o link.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (UrlUtils.isYouTube(url)) {
      return Tooltip(
        message: 'Abrir no YouTube',
        child: FilledButton.tonalIcon(
          onPressed: () => _open(context),
          icon: const YoutubeLogoIcon(size: 18),
          label: const Text('YouTube'),
        ),
      );
    }

    return IconButton(
      tooltip: 'Abrir link de referência',
      icon: const Icon(Icons.link),
      onPressed: () => _open(context),
    );
  }
}

/// Classic YouTube play-button mark (red rounded rectangle + white triangle).
class YoutubeLogoIcon extends StatelessWidget {
  const YoutubeLogoIcon({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.42,
      height: size,
      child: const CustomPaint(painter: _YoutubeLogoPainter()),
    );
  }
}

class _YoutubeLogoPainter extends CustomPainter {
  const _YoutubeLogoPainter();

  static const _red = Color(0xFFFF0000);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height * 0.22),
    );
    canvas.drawRRect(rect, Paint()..color = _red);

    final play = Path()
      ..moveTo(size.width * 0.38, size.height * 0.28)
      ..lineTo(size.width * 0.72, size.height * 0.5)
      ..lineTo(size.width * 0.38, size.height * 0.72)
      ..close();
    canvas.drawPath(play, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
