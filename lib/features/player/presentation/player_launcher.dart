import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/channel_video.dart';
import '../../../shared/models/tupic_channel.dart';
import '../../content/presentation/content_controller.dart';
import '../domain/playback_resume.dart';
import 'playback_progress_scope.dart';
import 'player_page.dart';

/// Unified playback entry for home, drawer, channel detail, and video taps.
Future<void> startChannelPlayback(
  BuildContext context, {
  required TupicChannel channel,
  int? startVideoIndex,
  String? startYoutubeVideoId,
}) async {
  final l10n = AppLocalizations.of(context);
  final content = ContentScope.of(context);
  final progressRepository = PlaybackProgressScope.maybeOf(context);
  await content.loadChannel(channel.id);

  final builtQueue = content.buildQueue(
    channelId: channel.id,
    playOrder: channel.playOrder,
  );

  if (!context.mounted) return;

  if (builtQueue.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.playerEmptyQueue)),
    );
    return;
  }

  // Explicit pick of an excluded/missing video.
  if (startYoutubeVideoId != null) {
    final inQueue = builtQueue.any(
      (v) => v.youtubeVideoId == startYoutubeVideoId,
    );
    if (!inQueue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.playerVideoUnavailable)),
      );
      return;
    }
  }

  final progress = progressRepository == null
      ? null
      : await progressRepository.getProgress(channel.id);

  if (!context.mounted) return;

  final plan = PlaybackResume.resolve(
    builtQueue: builtQueue,
    playOrder: channel.playOrder,
    progress: progress,
    forceYoutubeVideoId: startYoutubeVideoId,
    forceIndex: startVideoIndex,
  );

  if (plan.queue.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.playerEmptyQueue)),
    );
    return;
  }

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => PlayerPage(
        channel: channel,
        queue: List<ChannelVideo>.from(plan.queue),
        initialIndex: plan.index,
        initialStartSeconds: plan.startSeconds,
        progressRepository: progressRepository,
        resumed: plan.resumed,
      ),
    ),
  );
}

/// Backward-compatible alias.
Future<void> openChannelPlayer(
  BuildContext context, {
  required TupicChannel channel,
  int? startVideoIndex,
  String? startYoutubeVideoId,
}) {
  return startChannelPlayback(
    context,
    channel: channel,
    startVideoIndex: startVideoIndex,
    startYoutubeVideoId: startYoutubeVideoId,
  );
}
