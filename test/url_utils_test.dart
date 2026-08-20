import 'package:flutter_test/flutter_test.dart';
import 'package:louvor_app/core/utils/url_utils.dart';
import 'package:louvor_app/core/utils/validators.dart';

void main() {
  group('UrlUtils.normalize', () {
    test('returns null for empty input', () {
      expect(UrlUtils.normalize(null), isNull);
      expect(UrlUtils.normalize(''), isNull);
      expect(UrlUtils.normalize('   '), isNull);
    });

    test('adds https when the scheme is missing', () {
      expect(
        UrlUtils.normalize('youtube.com/watch?v=abc'),
        'https://youtube.com/watch?v=abc',
      );
    });

    test('keeps an existing scheme', () {
      expect(
        UrlUtils.normalize('http://example.com/song'),
        'http://example.com/song',
      );
    });
  });

  group('UrlUtils.tryParseHttp', () {
    test('parses a valid https url', () {
      expect(
        UrlUtils.tryParseHttp('https://youtu.be/abc')?.host,
        'youtu.be',
      );
    });

    test('rejects non-http schemes', () {
      expect(UrlUtils.tryParseHttp('javascript:alert(1)'), isNull);
      expect(UrlUtils.tryParseHttp('ftp://files.example.com'), isNull);
    });
  });

  group('UrlUtils.isYouTube', () {
    test('detects youtube hosts', () {
      expect(UrlUtils.isYouTube('https://www.youtube.com/watch?v=abc'), isTrue);
      expect(UrlUtils.isYouTube('https://youtu.be/abc'), isTrue);
      expect(UrlUtils.isYouTube('https://m.youtube.com/watch?v=abc'), isTrue);
      expect(UrlUtils.isYouTube('https://music.youtube.com/watch?v=abc'), isTrue);
    });

    test('is false for other sites', () {
      expect(UrlUtils.isYouTube('https://open.spotify.com/track/abc'), isFalse);
      expect(UrlUtils.isYouTube('https://example.com/youtube'), isFalse);
      expect(UrlUtils.isYouTube(''), isFalse);
    });
  });

  group('UrlUtils.youtubeVideoId', () {
    test('extracts a video id from common youtube url shapes', () {
      expect(
        UrlUtils.youtubeVideoId('https://youtu.be/nBBYAA7GWyw?si=tracking'),
        'nBBYAA7GWyw',
      );
      expect(
        UrlUtils.youtubeVideoId('https://www.youtube.com/watch?v=wXLL6vo8Pxs'),
        'wXLL6vo8Pxs',
      );
      expect(
        UrlUtils.youtubeVideoId('https://youtube.com/embed/abc123'),
        'abc123',
      );
      expect(
        UrlUtils.youtubeVideoId('https://www.youtube.com/shorts/shortId'),
        'shortId',
      );
    });

    test('is null when the url is not a youtube video', () {
      expect(UrlUtils.youtubeVideoId('https://open.spotify.com/track/abc'), isNull);
      expect(UrlUtils.youtubeVideoId('https://youtube.com'), isNull);
      expect(UrlUtils.youtubeVideoId(''), isNull);
    });
  });

  group('Validators.optionalUrl', () {
    test('allows empty', () {
      expect(Validators.optionalUrl(null), isNull);
      expect(Validators.optionalUrl(''), isNull);
    });

    test('rejects invalid urls', () {
      expect(Validators.optionalUrl('not a url'), isNotNull);
    });

    test('accepts a youtube link', () {
      expect(Validators.optionalUrl('https://youtu.be/abc'), isNull);
    });
  });
}
