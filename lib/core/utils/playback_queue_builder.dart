import 'dart:math';

import '../../shared/models/channel_video.dart';
import '../../shared/models/content_source.dart';
import '../../shared/models/play_order.dart';

/// Pure playback-queue builder for STEP 3A (no player UI yet).
class PlaybackQueueBuilder {
  const PlaybackQueueBuilder();

  /// Builds a deduped queue for a channel.
  ///
  /// Rules:
  /// 1. Process sources in registration order.
  /// 2. Collect confirmed video IDs linked to those sources.
  /// 3. Deduplicate by youtubeVideoId.
  /// 4. Drop excluded videos.
  /// 5. Respect manualOrder.
  /// 6. Shuffle a copy when [playOrder] is shuffle (source order unchanged).
  List<ChannelVideo> build({
    required List<ContentSource> sources,
    required List<ChannelVideo> videos,
    required PlayOrder playOrder,
    Random? random,
  }) {
    final sourceIds = sources.map((s) => s.id).toSet();
    final candidates = videos
        .where((video) => !video.isExcluded)
        .where(
          (video) =>
              video.sourceIds.any(sourceIds.contains) ||
              video.sourceIds.isEmpty,
        )
        .toList();

    // Prefer videos that are still linked to at least one remaining source.
    final linked = candidates
        .where((video) => video.sourceIds.any(sourceIds.contains))
        .toList();

    linked.sort((a, b) {
      final order = a.manualOrder.compareTo(b.manualOrder);
      if (order != 0) return order;
      return a.addedAt.compareTo(b.addedAt);
    });

    // Deduplicate while preserving order.
    final seen = <String>{};
    final unique = <ChannelVideo>[];
    for (final video in linked) {
      if (seen.add(video.youtubeVideoId)) {
        unique.add(video);
      }
    }

    if (playOrder == PlayOrder.shuffle) {
      final shuffled = List<ChannelVideo>.from(unique);
      shuffled.shuffle(random ?? Random());
      return shuffled;
    }
    return unique;
  }
}
