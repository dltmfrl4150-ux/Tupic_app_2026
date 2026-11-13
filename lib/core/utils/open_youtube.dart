import 'package:url_launcher/url_launcher.dart';

/// Opens the YouTube app when possible, otherwise the site in an external browser.
///
/// Returns `true` when a launch was accepted by the platform.
Future<bool> openYoutube({
  Future<bool> Function(Uri uri, {required LaunchMode mode})? launch,
  Future<bool> Function(Uri uri)? canLaunch,
}) async {
  final launchFn =
      launch ??
      ((Uri uri, {required LaunchMode mode}) =>
          launchUrl(uri, mode: mode));
  final canLaunchFn = canLaunch ?? canLaunchUrl;

  // Prefer the YouTube app deep link when the platform can handle it.
  final appUri = Uri.parse('vnd.youtube://www.youtube.com/');
  try {
    if (await canLaunchFn(appUri)) {
      final opened = await launchFn(
        appUri,
        mode: LaunchMode.externalApplication,
      );
      if (opened) return true;
    }
  } catch (_) {
    // Fall through to HTTPS — schemes may be unavailable on web/iOS.
  }

  final webUri = Uri.parse('https://www.youtube.com');
  try {
    final canOpenWeb = await canLaunchFn(webUri);
    if (canOpenWeb) {
      return await launchFn(webUri, mode: LaunchMode.externalApplication);
    }
    // Some platforms report canLaunch=false for https; still attempt launch.
    return await launchFn(webUri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
