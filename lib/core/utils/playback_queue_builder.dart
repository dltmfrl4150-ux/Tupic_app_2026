import 'dart:math';

import '../../shared/models/channel_video.dart';
import '../../shared/models/content_source.dart';
import '../../shared/models/play_order.dart';
import 'title_sort.dart';

/// Pure playback-queue builder (no player UI).
class PlaybackQueueBuilder {
  const PlaybackQueueBuilder();

  /// Builds a deduped queue for a channel.
  ///
  /// Rules:
  /// 1. Process sources in registration order (filter by link).
  /// 2. Collect confirmed video IDs linked to those sources.
  /// 3. Deduplicate by youtubeVideoId.
  /// 4. Drop excluded videos.
  /// 5. Apply [playOrder] (title / addedAt / shuffle). Does not mutate storage.
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

    // Deduplicate while preserving encounter order, then sort for playOrder.
    final seen = <String>{};
    final unique = <ChannelVideo>[];
    for (final video in linked) {
      if (seen.add(video.youtubeVideoId)) {
        unique.add(video);
      }
    }

    return _sorted(unique, playOrder, random);
  }

  List<ChannelVideo> _sorted(
    List<ChannelVideo> videos,
    PlayOrder playOrder,
    Random? random,
  ) {
    final sorted = List<ChannelVideo>.from(videos);

    switch (playOrder) {
      case PlayOrder.titleAsc:
        sorted.sort(_byTitleAsc);
      case PlayOrder.titleDesc:
        sorted.sort(_byTitleDesc);
      case PlayOrder.newestAdded:
        sorted.sort(_byNewestAdded);
      case PlayOrder.oldestAdded:
        sorted.sort(_byOldestAdded);
      case PlayOrder.shuffle:
        sorted.shuffle(random ?? Random());
    }
    return sorted;
  }

  static int _byTitleAsc(ChannelVideo a, ChannelVideo b) {
    final blank = _blankTitleRank(a, b);
    if (blank != 0) return blank;
    final byTitle = compareNaturalTitles(a.displayTitle, b.displayTitle);
    if (byTitle != 0) return byTitle;
    return _stableId(a, b);
  }

  static int _byTitleDesc(ChannelVideo a, ChannelVideo b) {
    final blank = _blankTitleRank(a, b);
    if (blank != 0) return blank;
    final byTitle = compareNaturalTitles(b.displayTitle, a.displayTitle);
    if (byTitle != 0) return byTitle;
    return _stableId(a, b);
  }

  /// Blank / provisional titles always sort after real titled videos.
  static int _blankTitleRank(ChannelVideo a, ChannelVideo b) {
    final aEmpty = _isBlankForSort(a);
    final bEmpty = _isBlankForSort(b);
    if (aEmpty == bEmpty) return 0;
    return aEmpty ? 1 : -1;
  }

  static bool _isBlankForSort(ChannelVideo video) {
    final custom = video.customTitle?.trim();
    if (custom != null && custom.isNotEmpty) return false;
    final original = video.originalTitle?.trim();
    if (original != null && original.isNotEmpty) return false;
    final legacy = video.title.trim();
    if (legacy.isEmpty) return true;
    return ChannelVideo.isProvisionalTitleText(legacy, video.youtubeVideoId);
  }

  static int _byNewestAdded(ChannelVideo a, ChannelVideo b) {
    final byAdded = b.addedAt.compareTo(a.addedAt);
    if (byAdded != 0) return byAdded;
    final byOrder = b.manualOrder.compareTo(a.manualOrder);
    if (byOrder != 0) return byOrder;
    return _stableId(a, b);
  }

  static int _byOldestAdded(ChannelVideo a, ChannelVideo b) {
    final byAdded = a.addedAt.compareTo(b.addedAt);
    if (byAdded != 0) return byAdded;
    final byOrder = a.manualOrder.compareTo(b.manualOrder);
    if (byOrder != 0) return byOrder;
    return _stableId(a, b);
  }

  static int _stableId(ChannelVideo a, ChannelVideo b) =>
      a.youtubeVideoId.compareTo(b.youtubeVideoId);
}
