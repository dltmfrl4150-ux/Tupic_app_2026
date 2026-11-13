/// Client-side plan limits. Paid billing is not wired.
///
/// [isPremium] is true only while a **debug** developer-UID test entitlement
/// is active (see [setDeveloperTestPremium]). Release builds stay free.
abstract final class PlanLimits {
  static const int freeMaxChannels = 1;
  static const int freeMaxVideosPerChannel = 100;
  static const int premiumMaxChannels = 30;
  static const int premiumMaxVideosPerChannel = 1000;
  static const int premiumMaxAutoSyncCreators = 10;

  static bool _developerTestPremium = false;

  /// Debug developer-test Premium only — not a paid subscription flag.
  static bool get isDeveloperTestPremium => _developerTestPremium;

  /// Effective premium for client limits (developer test until billing exists).
  static bool get isPremium => _developerTestPremium;

  /// Called from auth when the signed-in UID matches a local debug allow-list.
  static void setDeveloperTestPremium(bool value) {
    _developerTestPremium = value;
  }

  /// Resets entitlement state between tests.
  static void debugResetDeveloperTestPremium() {
    _developerTestPremium = false;
  }

  static int maxVideosPerChannel({required bool premium}) =>
      premium ? premiumMaxVideosPerChannel : freeMaxVideosPerChannel;

  static int maxChannels({required bool premium}) =>
      premium ? premiumMaxChannels : freeMaxChannels;
}
