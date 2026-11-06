import '../../../shared/models/channel_playback_progress.dart';
import '../../../shared/models/channel_video.dart';
import '../../../shared/models/play_order.dart';

class PlaybackStartPlan {
  const PlaybackStartPlan({
    required this.queue,
    required this.index,
    required this.startSeconds,
    required this.resumed,
  });

  final List<ChannelVideo> queue;
  final int index;
  final double startSeconds;
  final bool resumed;
}

/// Resolves resume index/position against a freshly built queue.
abstract final class PlaybackResume {
  /// Near-end threshold when duration is known (seconds).
  static const nearEndSeconds = 5.0;

  /// Positions within this of zero are treated as start.
  static const minMeaningfulSeconds = 1.0;

  static PlaybackStartPlan resolve({
    required List<ChannelVideo> builtQueue,
    required PlayOrder playOrder,
    ChannelPlaybackProgress? progress,
    String? forceYoutubeVideoId,
    int? forceIndex,
    double? knownDurationSeconds,
  }) {
    if (builtQueue.isEmpty) {
      return const PlaybackStartPlan(
        queue: [],
        index: -1,
        startSeconds: 0,
        resumed: false,
      );
    }

    // Explicit user pick overrides resume.
    if (forceYoutubeVideoId != null) {
      final found = builtQueue.indexWhere(
        (v) => v.youtubeVideoId == forceYoutubeVideoId,
      );
      if (found >= 0) {
        return PlaybackStartPlan(
          queue: builtQueue,
          index: found,
          startSeconds: 0,
          resumed: false,
        );
      }
      return PlaybackStartPlan(
        queue: builtQueue,
        index: 0,
        startSeconds: 0,
        resumed: false,
      );
    }
    if (forceIndex != null) {
      return PlaybackStartPlan(
        queue: builtQueue,
        index: forceIndex.clamp(0, builtQueue.length - 1),
        startSeconds: 0,
        resumed: false,
      );
    }

    var queue = List<ChannelVideo>.from(builtQueue);

    // Prefer saved shuffle session order when still compatible.
    if (progress != null &&
        progress.sessionPlayOrder == PlayOrder.shuffle &&
        playOrder == PlayOrder.shuffle &&
        progress.sessionQueueIds != null &&
        progress.sessionQueueIds!.isNotEmpty) {
      final byId = {for (final v in builtQueue) v.youtubeVideoId: v};
      final restored = <ChannelVideo>[];
      final seen = <String>{};
      for (final id in progress.sessionQueueIds!) {
        final video = byId[id];
        if (video != null && seen.add(id)) {
          restored.add(video);
        }
      }
      for (final video in builtQueue) {
        if (seen.add(video.youtubeVideoId)) {
          restored.add(video);
        }
      }
      if (restored.isNotEmpty) {
        queue = restored;
      }
    }

    if (progress == null) {
      return PlaybackStartPlan(
        queue: queue,
        index: 0,
        startSeconds: 0,
        resumed: false,
      );
    }

    final index = queue.indexWhere(
      (v) => v.youtubeVideoId == progress.youtubeVideoId,
    );
    if (index < 0) {
      // Last watched video was pruned/excluded — advance to the next id in
      // the saved session order when possible; otherwise start at the first.
      final savedIds = progress.sessionQueueIds;
      if (savedIds != null && savedIds.isNotEmpty) {
        final savedIdx = savedIds.indexOf(progress.youtubeVideoId);
        final startSearch = savedIdx >= 0 ? savedIdx + 1 : 0;
        for (var i = startSearch; i < savedIds.length; i++) {
          final next = queue.indexWhere((v) => v.youtubeVideoId == savedIds[i]);
          if (next >= 0) {
            return PlaybackStartPlan(
              queue: queue,
              index: next,
              startSeconds: 0,
              resumed: true,
            );
          }
        }
      }
      return PlaybackStartPlan(
        queue: queue,
        index: 0,
        startSeconds: 0,
        resumed: false,
      );
    }

    var seconds = progress.positionSeconds;
    if (!seconds.isFinite || seconds < 0) {
      seconds = 0;
    }
    if (seconds < minMeaningfulSeconds) {
      seconds = 0;
    }

    final duration = knownDurationSeconds;
    if (duration != null && duration > 0 && seconds >= duration - nearEndSeconds) {
      // Treat as finished — start next video or wrap to first at 0.
      if (index < queue.length - 1) {
        return PlaybackStartPlan(
          queue: queue,
          index: index + 1,
          startSeconds: 0,
          resumed: true,
        );
      }
      return PlaybackStartPlan(
        queue: queue,
        index: index,
        startSeconds: 0,
        resumed: true,
      );
    }

    return PlaybackStartPlan(
      queue: queue,
      index: index,
      startSeconds: seconds,
      resumed: true,
    );
  }
}
