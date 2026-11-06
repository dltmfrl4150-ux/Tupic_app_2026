import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Portrait for app chrome, landscape for the player screen only.
abstract final class OrientationHelper {
  static Future<void> lockPortrait() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  static Future<void> lockLandscape() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// Web browsers typically cannot force orientation — UI adapts instead.
  static bool get supportsForcedOrientation => !kIsWeb;
}
