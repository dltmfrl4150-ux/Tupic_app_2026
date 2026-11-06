import 'package:flutter/foundation.dart';

/// Local STEP 4A YouTube proxy. Never used in release builds.
abstract final class DevApiConfig {
  static const int localPort = 8787;

  /// Empty in release — playlist fetch must not hit a local proxy in production.
  static String get youtubeProxyBaseUrl {
    if (kReleaseMode) return '';
    if (kIsWeb) return 'http://127.0.0.1:$localPort';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator loopback to host machine.
        return 'http://10.0.2.2:$localPort';
      default:
        return 'http://127.0.0.1:$localPort';
    }
  }

  static bool get isPlaylistFetchAvailable => youtubeProxyBaseUrl.isNotEmpty;
}
