import 'content_category.dart';
import 'tupic_channel.dart';
import 'video_item.dart';

enum AudiencePreference { kids, general }

class HomeFeed {
  const HomeFeed({
    required this.userDisplayName,
    required this.channels,
    required this.recommended,
    required this.exploreVideos,
    required this.lastAudience,
    this.isMock = true,
  });

  final String userDisplayName;
  final List<TupicChannel> channels;
  final List<VideoItem> recommended;
  final List<VideoItem> exploreVideos;
  final AudiencePreference? lastAudience;
  final bool isMock;

  HomeFeed copyWith({
    String? userDisplayName,
    List<TupicChannel>? channels,
    List<VideoItem>? recommended,
    List<VideoItem>? exploreVideos,
    AudiencePreference? lastAudience,
    bool? isMock,
  }) {
    return HomeFeed(
      userDisplayName: userDisplayName ?? this.userDisplayName,
      channels: channels ?? this.channels,
      recommended: recommended ?? this.recommended,
      exploreVideos: exploreVideos ?? this.exploreVideos,
      lastAudience: lastAudience ?? this.lastAudience,
      isMock: isMock ?? this.isMock,
    );
  }

  List<VideoItem> exploreByCategory(ContentCategory category) {
    if (category == ContentCategory.all) {
      return exploreVideos;
    }
    return exploreVideos.where((v) => v.category == category).toList();
  }
}

sealed class HomeFeedState {
  const HomeFeedState();
}

class HomeFeedLoading extends HomeFeedState {
  const HomeFeedLoading();
}

class HomeFeedReady extends HomeFeedState {
  const HomeFeedReady(this.feed);
  final HomeFeed feed;
}

class HomeFeedEmpty extends HomeFeedState {
  const HomeFeedEmpty({required this.userDisplayName, this.isMock = true});
  final String userDisplayName;
  final bool isMock;
}

class HomeFeedError extends HomeFeedState {
  const HomeFeedError(this.message);
  final String message;
}
