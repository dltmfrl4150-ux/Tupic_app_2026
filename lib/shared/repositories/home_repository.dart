import '../models/home_feed.dart';

/// Abstraction so Mock can be swapped for Firebase/YouTube later.
abstract class HomeRepository {
  Future<HomeFeed> fetchHomeFeed({AudiencePreference? audienceOverride});
}
