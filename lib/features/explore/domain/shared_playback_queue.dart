import '../../../core/utils/playback_queue_builder.dart';
import '../../../shared/models/channel_video.dart';
import '../../../shared/models/content_enums.dart';
import '../../../shared/models/play_order.dart';
import '../../../shared/models/share_models.dart';
import '../../../shared/models/tupic_channel.dart';
import '../../../shared/models/video_item.dart';

/// In-memory read-only playback plan for a published share snapshot.
///
/// Does not create or mutate local channels / SharedPreferences.
class SharedPlaybackPlan {
  const SharedPlaybackPlan({
    required this.sessionChannel,
    required this.queue,
    required this.initialIndex,
    required this.postId,
    required this.version,
  });

  /// Synthetic channel identity for [PlayerPage] only (not persisted).
  final TupicChannel sessionChannel;
  final List<ChannelVideo> queue;
  final int initialIndex;
  final String postId;
  final int version;

  bool get isEmpty => queue.isEmpty;
}

/// Builds a shared preview playback plan from an immutable [SharePost] snapshot.
abstract final class SharedPlaybackQueue {
  static const _sessionIdPrefix = 'shared_preview__';

  static bool isSharedSessionChannelId(String id) =>
      id.startsWith(_sessionIdPrefix);

  static String sessionChannelIdForPost(String postId) =>
      '$_sessionIdPrefix$postId';

  /// Returns null when there are no playable videos.
  static SharedPlaybackPlan? build(
    SharePost post, {
    String? startYoutubeVideoId,
    int? startIndex,
    PlaybackQueueBuilder queueBuilder = const PlaybackQueueBuilder(),
  }) {
    if (!post.isPublished) return null;

    final sessionId = sessionChannelIdForPost(post.id);
    final playOrder = PlayOrderX.fromStorage(post.snapshot.playOrder);
    final mapped = post.snapshot.videos
        .map((v) => _toChannelVideo(v, sessionId))
        .toList(growable: false);

    final queue = queueBuilder.buildOrderedVideos(
      videos: mapped,
      playOrder: playOrder,
    );
    if (queue.isEmpty) return null;

    var index = 0;
    if (startYoutubeVideoId != null && startYoutubeVideoId.isNotEmpty) {
      final found = queue.indexWhere(
        (v) => v.youtubeVideoId == startYoutubeVideoId,
      );
      if (found < 0) return null;
      index = found;
    } else if (startIndex != null) {
      if (startIndex < 0 || startIndex >= queue.length) return null;
      index = startIndex;
    }

    final accent = post.snapshot.accentColor;
    final sessionChannel = TupicChannel(
      id: sessionId,
      name: post.snapshot.channelName.trim().isEmpty
          ? post.title
          : post.snapshot.channelName.trim(),
      isKidsChannel: post.snapshot.isKidsChannel || post.isKids,
      videoCount: queue.length,
      accentColor: ColorSeed(accent ?? 0xFF6B4C9A),
      createdAt: post.createdAt,
      playOrder: playOrder,
      coverLabel: post.snapshot.coverLabel,
    );

    return SharedPlaybackPlan(
      sessionChannel: sessionChannel,
      queue: queue,
      initialIndex: index,
      postId: post.id,
      version: post.version,
    );
  }

  static ChannelVideo _toChannelVideo(
    ShareSnapshotVideo video,
    String sessionChannelId,
  ) {
    final id = video.youtubeVideoId.trim();
    final title = video.title.trim().isEmpty
        ? ChannelVideo.provisionalTitle(id)
        : video.title.trim();
    return ChannelVideo(
      youtubeVideoId: id,
      tupicChannelId: sessionChannelId,
      sourceIds: const [],
      title: title,
      originalTitle: video.originalTitle ?? title,
      customTitle: video.customTitle,
      thumbnailUrl: video.thumbnailUrl ?? ChannelVideo.defaultThumbnailUrl(id),
      durationSeconds: video.durationSeconds,
      metadataStatus: MetadataStatus.resolved,
      // Snapshot has no addedAt; preserve published order via manualOrder.
      addedAt: DateTime.fromMillisecondsSinceEpoch(video.manualOrder),
      manualOrder: video.manualOrder,
      isExcluded: false,
    );
  }
}
