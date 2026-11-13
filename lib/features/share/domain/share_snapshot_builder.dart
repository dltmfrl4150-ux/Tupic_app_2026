import '../../../shared/models/channel_video.dart';
import '../../../shared/models/content_source.dart';
import '../../../shared/models/play_order.dart';
import '../../../shared/models/share_models.dart';
import '../../../shared/models/tupic_channel.dart';

class ShareSnapshotBuildResult {
  const ShareSnapshotBuildResult.ok(this.snapshot) : errorCode = null;
  const ShareSnapshotBuildResult.error(this.errorCode) : snapshot = null;

  final ShareSnapshot? snapshot;
  final String? errorCode;

  bool get isOk => snapshot != null && errorCode == null;
}

/// Builds an immutable share snapshot from local channel state.
abstract final class ShareSnapshotBuilder {
  /// Max videos in one Firestore share document (aligned with Premium ceiling).
  static const int maxVideosInSnapshot = 1000;

  static ShareSnapshotBuildResult build({
    required TupicChannel channel,
    required List<ChannelVideo> videos,
    required List<ContentSource> sources,
  }) {
    for (final source in sources) {
      final url = source.originalUrl.trim().toLowerCase();
      if (url.startsWith('file:') ||
          url.startsWith('content:') ||
          url.startsWith('/') ||
          url.contains(':\\')) {
        return const ShareSnapshotBuildResult.error('non_shareable_source');
      }
    }

    final active = videos.where((v) => !v.isExcluded).toList(growable: false)
      ..sort((a, b) => a.manualOrder.compareTo(b.manualOrder));

    if (active.isEmpty) {
      return const ShareSnapshotBuildResult.error('no_videos');
    }
    if (active.length > maxVideosInSnapshot) {
      return const ShareSnapshotBuildResult.error('too_many_videos');
    }

    final snapshotVideos = <ShareSnapshotVideo>[];
    for (var i = 0; i < active.length; i++) {
      final video = active[i];
      final id = video.youtubeVideoId.trim();
      if (id.isEmpty || id.length > 64) {
        return const ShareSnapshotBuildResult.error('invalid_video');
      }
      final thumb = video.thumbnailUrl?.trim();
      if (thumb != null &&
          thumb.isNotEmpty &&
          !(thumb.startsWith('https://') || thumb.startsWith('http://'))) {
        return const ShareSnapshotBuildResult.error('non_shareable_source');
      }
      snapshotVideos.add(
        ShareSnapshotVideo(
          youtubeVideoId: id,
          title: video.displayTitle,
          originalTitle: video.originalTitle,
          customTitle: video.hasCustomTitle ? video.customTitle : null,
          thumbnailUrl: (thumb == null || thumb.isEmpty) ? null : thumb,
          durationSeconds: video.durationSeconds,
          manualOrder: i,
        ),
      );
    }

    return ShareSnapshotBuildResult.ok(
      ShareSnapshot(
        channelName: channel.name.trim(),
        isKidsChannel: channel.isKidsChannel,
        playOrder: channel.playOrder.storageValue,
        coverLabel: channel.coverLabel,
        accentColor: channel.accentColor.value,
        videos: snapshotVideos,
      ),
    );
  }
}
