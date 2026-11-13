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
import '../../share/presentation/share_channel_page.dart';
import 'channel_manage_page.dart';
import 'channels_controller.dart';

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

  Future<void> _openChannelSettings(TupicChannel channel) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChannelManagePage(channelId: channel.id),
      ),
    );
  }

  Future<void> _openContentManage(TupicChannel channel) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContentManagePage(channelId: channel.id),
      ),
    );
    if (!mounted) return;
    await ContentScope.of(context).loadChannel(widget.channelId);
  }

  Future<void> _openAddContent(TupicChannel channel) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddContentPage(channelId: channel.id),
      ),
    );
    if (!mounted) return;
    await ContentScope.of(context).loadChannel(widget.channelId);
  }

  String _playOrderLabel(AppLocalizations l10n, PlayOrder order) {
    return switch (order) {
      PlayOrder.titleAsc => l10n.playOrderTitleAsc,
      PlayOrder.titleDesc => l10n.playOrderTitleDesc,
      PlayOrder.newestAdded => l10n.playOrderNewestAdded,
      PlayOrder.oldestAdded => l10n.playOrderOldestAdded,
      PlayOrder.shuffle => l10n.playOrderShuffle,
    };
  }

  Future<void> _pickPlayOrder(TupicChannel channel) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<PlayOrder>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  l10n.playOrderLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final order in PlayOrder.values)
                ListTile(
                  title: Text(_playOrderLabel(l10n, order)),
                  trailing: channel.playOrder == order
                      ? const Icon(
                          Icons.check_rounded,
                          color: TupicColors.accentViolet,
                        )
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(order),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (selected == null || selected == channel.playOrder || !mounted) return;
    await ChannelsScope.of(context).updatePlayOrder(
      id: channel.id,
      playOrder: selected,
    );
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
        final playOrderLabel = _playOrderLabel(l10n, channel.playOrder);
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
                tooltip: l10n.channelSettingsTooltip,
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _openChannelSettings(channel!),
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
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: TupicColors.mutedText,
                ),
                onTap: () => _pickPlayOrder(channel!),
              ),
              _InfoTile(
                label: l10n.queuePreviewCount(queue.length),
                icon: Icons.playlist_play_rounded,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _openAddContent(channel!),
                icon: const Icon(Icons.add_link),
                label: Text(l10n.addContentTitle),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _openContentManage(channel!),
                icon: const Icon(Icons.library_add_check_outlined),
                label: Text(l10n.manageContentTitle),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('share_channel_button'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ShareChannelPage(channel: channel!),
                    ),
                  );
                },
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(l10n.shareChannelAction),
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
                        ? '${video.displayTitle} (${l10n.videoExcluded})'
                        : video.displayTitle,
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
    this.trailing,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final String? subtitle;
  final Widget? trailing;
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
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
