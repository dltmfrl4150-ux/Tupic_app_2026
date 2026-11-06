import 'package:flutter/material.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../core/constants/plan_limits.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/content_enums.dart';
import '../../../shared/models/play_order.dart';
import '../../../shared/models/tupic_channel.dart';
import '../../content/presentation/add_content_page.dart';
import '../../content/presentation/content_controller.dart';
import '../../content/presentation/content_manage_page.dart';
import '../../player/presentation/player_launcher.dart';
import 'channel_manage_page.dart';
import 'channels_controller.dart';
import 'parental_gate_dialog.dart';

class ChannelDetailPage extends StatefulWidget {
  const ChannelDetailPage({super.key, required this.channelId});

  final String channelId;

  @override
  State<ChannelDetailPage> createState() => _ChannelDetailPageState();
}

class _ChannelDetailPageState extends State<ChannelDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ContentScope.of(context).loadChannel(widget.channelId);
    });
  }

  Future<void> _openChannelSettings(
    BuildContext context,
    TupicChannel channel,
  ) async {
    if (channel.isKidsChannel) {
      final passed = await showParentalGateDialog(context);
      if (!passed || !context.mounted) return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChannelManagePage(channelId: channel.id),
      ),
    );
  }

  Future<void> _openContentManage(
    BuildContext context,
    TupicChannel channel,
  ) async {
    if (channel.isKidsChannel) {
      final passed = await showParentalGateDialog(context);
      if (!passed || !context.mounted) return;
    }
    if (!mounted) return;
    await Navigator.of(this.context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContentManagePage(channelId: channel.id),
      ),
    );
    if (!mounted) return;
    await ContentScope.of(this.context).loadChannel(widget.channelId);
  }

  Future<void> _openAddContent(
    BuildContext context,
    TupicChannel channel,
  ) async {
    if (channel.isKidsChannel) {
      final passed = await showParentalGateDialog(context);
      if (!passed || !mounted) return;
    }
    if (!mounted) return;
    await Navigator.of(this.context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddContentPage(channelId: channel.id),
      ),
    );
    if (!mounted) return;
    await ContentScope.of(this.context).loadChannel(widget.channelId);
  }

  IconData _sourceIcon(ContentSourceType type) {
    return switch (type) {
      ContentSourceType.video => Icons.movie_outlined,
      ContentSourceType.playlist => Icons.playlist_play,
      ContentSourceType.creator => Icons.person_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final channelsController = ChannelsScope.of(context);
    final contentController = ContentScope.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([channelsController, contentController]),
      builder: (context, _) {
        TupicChannel? channel;
        for (final item in channelsController.channels) {
          if (item.id == widget.channelId) {
            channel = item;
            break;
          }
        }

        if (channel == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.channelDetailTitle),
              leading: IconButton(
                tooltip: l10n.back,
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            body: Center(child: Text(l10n.channelNotFound)),
          );
        }

        final accent = Color(channel.accentColor.value);
        final playOrderLabel = channel.playOrder == PlayOrder.shuffle
            ? l10n.playOrderShuffle
            : l10n.playOrderSequential;
        final activeCount = contentController.activeCountFor(channel.id);
        final maxVideos = PlanLimits.maxVideosPerChannel(
          premium: PlanLimits.isPremium,
        );
        final sources = contentController.sourcesFor(channel.id);
        final videos = contentController.videosFor(channel.id);
        final queue = contentController.buildQueue(
          channelId: channel.id,
          playOrder: channel.playOrder,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(channel.name),
            leading: IconButton(
              tooltip: l10n.back,
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              IconButton(
                tooltip: l10n.menuManageChannels,
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _openChannelSettings(context, channel!),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.95),
                      TupicColors.selected,
                    ],
                  ),
                  border: Border.all(color: TupicColors.borderSubtle),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        channel.isKidsChannel
                            ? l10n.kidsBadge
                            : l10n.generalBadge,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      channel.coverLabel ?? 'TUPIC',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      channel.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoTile(
                label: l10n.videoLimitLabel(activeCount, maxVideos),
                icon: Icons.ondemand_video_outlined,
              ),
              _InfoTile(
                label: '${l10n.playOrderLabel}: $playOrderLabel',
                icon: Icons.queue_music_rounded,
              ),
              _InfoTile(
                label: l10n.queuePreviewCount(queue.length),
                icon: Icons.playlist_play_rounded,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _openAddContent(context, channel!),
                icon: const Icon(Icons.add_link),
                label: Text(l10n.addContentTitle),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _openContentManage(context, channel!),
                icon: const Icon(Icons.library_add_check_outlined),
                label: Text(l10n.manageContentTitle),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _openChannelSettings(context, channel!),
                icon: const Icon(Icons.tune_rounded),
                label: Text(l10n.manageThisChannel),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => startChannelPlayback(
                  context,
                  channel: channel!,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.playChannel),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.contentSourcesSection,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.sourceVsPlayableCount(sources.length, queue.length),
                style: const TextStyle(
                  color: TupicColors.mutedText,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              if (sources.isEmpty)
                Text(
                  l10n.emptySourcesBody,
                  style: const TextStyle(color: TupicColors.mutedText),
                )
              else
                ...sources.take(5).map((source) {
                  final String? subtitle;
                  if (source.sourceType == ContentSourceType.playlist) {
                    subtitle = switch (source.importStatus) {
                      ImportStatus.fetched ||
                      ImportStatus.partiallyFetched =>
                        l10n.playlistFetchedCount(source.fetchedVideoCount),
                      ImportStatus.failed => l10n.importStatusFailed,
                      _ => l10n.playlistFetchPending,
                    };
                  } else if (source.sourceType == ContentSourceType.creator) {
                    subtitle = l10n.playlistFetchPending;
                  } else {
                    subtitle = null;
                  }
                  return _InfoTile(
                    label: source.displayName,
                    icon: _sourceIcon(source.sourceType),
                    subtitle: subtitle,
                  );
                }),
              const SizedBox(height: 12),
              Text(
                l10n.contentVideosSection,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.playableVideosOnlyHint,
                style: const TextStyle(
                  color: TupicColors.mutedText,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              if (videos.isEmpty)
                Text(
                  l10n.emptyVideosBody,
                  style: const TextStyle(color: TupicColors.mutedText),
                )
              else
                ...videos.take(8).map((video) {
                  return _InfoTile(
                    label: video.isExcluded
                        ? '${video.title} (${l10n.videoExcluded})'
                        : video.title,
                    icon: Icons.play_circle_outline,
                    onTap: video.isExcluded
                        ? null
                        : () => startChannelPlayback(
                              context,
                              channel: channel!,
                              startYoutubeVideoId: video.youtubeVideoId,
                            ),
                  );
                }),
              if (sources.any(
                (s) =>
                    s.importStatus == ImportStatus.pendingFetch ||
                    s.sourceType != ContentSourceType.video,
              )) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.playlistVideosNotFetchedYet,
                  style: const TextStyle(
                    color: TupicColors.mutedText,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.icon,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: TupicColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TupicColors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(icon, color: TupicColors.accentViolet, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: TupicColors.primaryText),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: TupicColors.mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
