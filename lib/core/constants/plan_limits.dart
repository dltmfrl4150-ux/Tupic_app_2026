/// Client-side plan limits. Values should later come from the server.
abstract final class PlanLimits {
  static const int freeMaxChannels = 1;
  static const int freeMaxVideosPerChannel = 100;
  static const int premiumMaxChannels = 30;
  static const int premiumMaxVideosPerChannel = 1000;
  static const int premiumMaxAutoSyncCreators = 10;

  /// STEP 3A: billing is not wired; treat all users as free entitlements.
  static const bool isPremium = false;

  static int maxVideosPerChannel({required bool premium}) =>
      premium ? premiumMaxVideosPerChannel : freeMaxVideosPerChannel;

  static int maxChannels({required bool premium}) =>
      premium ? premiumMaxChannels : freeMaxChannels;
}
