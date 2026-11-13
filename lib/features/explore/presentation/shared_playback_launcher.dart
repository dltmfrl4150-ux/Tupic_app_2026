import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/share_models.dart';
import '../../player/presentation/player_page.dart';
import '../domain/shared_playback_queue.dart';

/// Opens the existing [PlayerPage] for a shared snapshot (no local channel).
///
/// Progress is not persisted ([PlayerPage.progressRepository] stays null).
Future<void> startSharedChannelPlayback(
  BuildContext context, {
  required SharePost post,
  String? startYoutubeVideoId,
  int? startIndex,
}) async {
  final l10n = AppLocalizations.of(context);

  if (!post.isPublished) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.sharePreviewUnavailable)),
    );
    return;
  }

  final plan = SharedPlaybackQueue.build(
    post,
    startYoutubeVideoId: startYoutubeVideoId,
    startIndex: startIndex,
  );

  if (plan == null || plan.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          startYoutubeVideoId != null
              ? l10n.playerVideoUnavailable
              : l10n.playerEmptyQueue,
        ),
      ),
    );
    return;
  }

  if (!context.mounted) return;

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => PlayerPage(
        channel: plan.sessionChannel,
        queue: List.from(plan.queue),
        initialIndex: plan.initialIndex,
        initialStartSeconds: 0,
        // Shared preview: session-only; never write local progress keys.
        progressRepository: null,
        resumed: false,
      ),
    ),
  );
}
