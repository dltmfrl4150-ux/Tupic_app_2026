import 'package:flutter_test/flutter_test.dart';
import 'package:tupic/core/utils/open_youtube.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  test('opens YouTube app scheme when available', () async {
    final launched = <Uri>[];
    final ok = await openYoutube(
      canLaunch: (uri) async => uri.scheme == 'vnd.youtube',
      launch: (uri, {required LaunchMode mode}) async {
        launched.add(uri);
        expect(mode, LaunchMode.externalApplication);
        return true;
      },
    );
    expect(ok, isTrue);
    expect(launched, [Uri.parse('vnd.youtube://www.youtube.com/')]);
  });

  test('falls back to https when app scheme fails', () async {
    final launched = <Uri>[];
    final ok = await openYoutube(
      canLaunch: (uri) async => uri.scheme == 'https',
      launch: (uri, {required LaunchMode mode}) async {
        launched.add(uri);
        return true;
      },
    );
    expect(ok, isTrue);
    expect(launched.single, Uri.parse('https://www.youtube.com'));
  });

  test('falls back when app launch returns false', () async {
    final launched = <Uri>[];
    final ok = await openYoutube(
      canLaunch: (_) async => true,
      launch: (uri, {required LaunchMode mode}) async {
        launched.add(uri);
        return uri.scheme == 'https';
      },
    );
    expect(ok, isTrue);
    expect(launched.map((u) => u.scheme), ['vnd.youtube', 'https']);
  });

  test('returns false when all launches fail', () async {
    final ok = await openYoutube(
      canLaunch: (_) async => true,
      launch: (uri, {required LaunchMode mode}) async => false,
    );
    expect(ok, isFalse);
  });

  test('returns false when launch throws after app failure', () async {
    final ok = await openYoutube(
      canLaunch: (_) async => true,
      launch: (uri, {required LaunchMode mode}) async {
        if (uri.scheme == 'vnd.youtube') return false;
        throw Exception('blocked');
      },
    );
    expect(ok, isFalse);
  });
}
