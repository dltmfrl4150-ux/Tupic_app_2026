import 'package:flutter/material.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/channel_video.dart';
import '../../../shared/models/content_enums.dart';
import '../../../shared/models/content_source.dart';
import '../../../shared/models/playlist_fetch_models.dart';
import '../../../shared/repositories/content_repository.dart';
import 'add_content_page.dart';
import 'content_controller.dart';

class ContentManagePage extends StatefulWidget {
  const ContentManagePage({super.key, required this.channelId});

  final String channelId;

  @override
  State<ContentManagePage> createState() => _ContentManagePageState();
}

class _ContentManagePageState extends State<ContentManagePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ContentScope.of(context).loadChannel(widget.channelId);
    });
  }

  Future<void> _confirmDeleteSource(ContentSource source) async {
    final l10n = AppLocalizations.of(context);
    final content = ContentScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteSourceTitle),
          content: Text(l10n.deleteSourceBody(source.displayName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    final impact = await content.deleteSource(
      channelId: widget.channelId,
      sourceId: source.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.deleteSourceResult(
            impact.removedVideoCount,
            impact.retainedVideoCount,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteVideo(ChannelVideo video) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteVideoTitle),
          content: Text(l10n.deleteVideoBody(video.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    await ContentScope.of(context).deleteVideo(
      channelId: widget.channelId,
      youtubeVideoId: video.youtubeVideoId,
    );
  }

  String _sourceTypeLabel(AppLocalizations l10n, ContentSourceType type) {
    return switch (type) {
      ContentSourceType.video => l10n.contentTypeVideo,
      ContentSourceType.playlist => l10n.contentTypePlaylist,
      ContentSourceType.creator => l10n.contentTypeCreator,
    };
  }

  String _statusLabel(
    AppLocalizations l10n,
    ContentSource source, {
    required bool fetching,
  }) {
    if (fetching) return l10n.importStatusFetching;
    return switch (source.importStatus) {
      ImportStatus.ready => l10n.importStatusReady,
      ImportStatus.pendingFetch => l10n.importStatusPending,
      ImportStatus.fetching => l10n.importStatusFetching,
      ImportStatus.fetched => l10n.playlistFetchedCount(source.fetchedVideoCount),
      ImportStatus.partiallyFetched =>
        '${l10n.importStatusPartial} · ${l10n.playlistFetchedCount(source.fetchedVideoCount)}',
      ImportStatus.failed => l10n.importStatusFailed,
    };
  }

  Future<void> _fetchPlaylist(ContentSource source, {bool refresh = false}) async {
    final l10n = AppLocalizations.of(context);
    final content = ContentScope.of(context);
    try {
      final report = await content.fetchPlaylistVideos(
        channelId: widget.channelId,
        sourceId: source.id,
        forceRefresh: refresh,
      );
      if (!mounted) return;
      final summary = StringBuffer(
        l10n.playlistFetchReport(
          report.importedCount,
          report.excludedPrivateDeleted + report.excludedMissing,
          report.excludedNotEmbeddable,
          report.duplicateCount,
        ),
      );
      if (report.prunedUnplayableCount > 0) {
        summary.write('\n');
        summary.write(
          l10n.playlistFetchReportPruned(report.prunedUnplayableCount),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(summary.toString())),
      );
    } on YoutubeApiException catch (error) {
      if (!mounted) return;
      final message = error.isMissingApiKey
          ? l10n.localApiKeyRequired
          : error.isQuotaExceeded
          ? l10n.quotaExceededMessage
          : error.isDailyLimit
          ? l10n.dailyLocalLimitMessage
          : error.isConnectionFailed
          ? l10n.localServerRequired
          : error.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on VideoLimitExceededException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.contentVideoLimit(error.maxVideos))),
      );
    } catch (error, stack) {
      debugPrint('ContentManagePage fetch error: $error');
      debugPrintStack(stackTrace: stack);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.playlistFetchUnexpectedError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content = ContentScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageContentTitle),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            tooltip: l10n.addContentTitle,
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AddContentPage(channelId: widget.channelId),
                ),
              );
              if (mounted) {
                await content.loadChannel(widget.channelId);
              }
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: content,
        builder: (context, _) {
          if (content.loading &&
              content.sourcesFor(widget.channelId).isEmpty &&
              content.videosFor(widget.channelId).isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final sources = content.sourcesFor(widget.channelId);
          final videos = content.videosFor(widget.channelId);

          return ReorderableListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.contentSourcesSection,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (sources.isEmpty)
                  _EmptyBox(text: l10n.emptySourcesBody)
                else
                  ...sources.map((source) {
                    final fetching = content.isFetchingSource(source.id);
                    final isPlaylist =
                        source.sourceType == ContentSourceType.playlist;
                    final canFetch = isPlaylist &&
                        source.youtubePlaylistId != null &&
                        !fetching;
                    final showRetry = isPlaylist &&
                        (source.importStatus == ImportStatus.failed ||
                            source.importStatus == ImportStatus.pendingFetch ||
                            source.importStatus ==
                                ImportStatus.partiallyFetched ||
                            source.importStatus == ImportStatus.fetched);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: TupicColors.card,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: TupicColors.borderSubtle,
                            ),
                          ),
                          title: Text(
                            source.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_sourceTypeLabel(l10n, source.sourceType)} · ${_statusLabel(l10n, source, fetching: fetching)}',
                              ),
                              if (source.lastFetchedAt != null)
                                Text(
                                  l10n.lastFetchedAtLabel(
                                    source.lastFetchedAt!
                                        .toLocal()
                                        .toString()
                                        .split('.')
                                        .first,
                                  ),
                                  style: const TextStyle(
                                    color: TupicColors.mutedText,
                                    fontSize: 11,
                                  ),
                                ),
                              if (source.lastErrorMessage != null &&
                                  source.lastErrorMessage!.isNotEmpty)
                                Text(
                                  source.lastErrorMessage!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: TupicColors.error,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (canFetch && showRetry)
                                IconButton(
                                  tooltip: source.importStatus ==
                                              ImportStatus.failed ||
                                          source.importStatus ==
                                              ImportStatus.partiallyFetched ||
                                          source.importStatus ==
                                              ImportStatus.fetched
                                      ? l10n.retryFetchPlaylist
                                      : l10n.fetchPlaylistVideos,
                                  icon: fetching
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          source.importStatus ==
                                                  ImportStatus.pendingFetch
                                              ? Icons.cloud_download_outlined
                                              : Icons.refresh,
                                        ),
                                  onPressed: fetching
                                      ? null
                                      : () => _fetchPlaylist(
                                            source,
                                            refresh: source.importStatus ==
                                                    ImportStatus.fetched ||
                                                source.importStatus ==
                                                    ImportStatus
                                                        .partiallyFetched ||
                                                source.importStatus ==
                                                    ImportStatus.failed,
                                          ),
                                ),
                              IconButton(
                                tooltip: l10n.delete,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDeleteSource(source),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                if (sources.any(
                  (s) => s.sourceType == ContentSourceType.creator,
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      l10n.apiNotConnectedBanner,
                      style: const TextStyle(
                        color: TupicColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Text(
                  l10n.contentVideosSection,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.reorderHint,
                  style: const TextStyle(
                    color: TupicColors.mutedText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                if (videos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _EmptyBox(text: l10n.emptyVideosBody),
                  ),
              ],
            ),
            onReorderItem: (oldIndex, newIndex) async {
              final items = [...videos];
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);
              await content.reorderVideos(
                channelId: widget.channelId,
                youtubeVideoIdsInOrder:
                    items.map((v) => v.youtubeVideoId).toList(),
              );
            },
            children: [
              for (final video in videos)
                Material(
                  key: ValueKey(video.youtubeVideoId),
                  color: TupicColors.card,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: TupicColors.borderSubtle),
                    ),
                    leading: _Thumb(url: video.thumbnailUrl),
                    title: Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        decoration: video.isExcluded
                            ? TextDecoration.lineThrough
                            : null,
                        color: video.isExcluded
                            ? TupicColors.mutedText
                            : TupicColors.primaryText,
                      ),
                    ),
                    subtitle: Text(
                      video.isExcluded
                          ? l10n.videoExcluded
                          : video.youtubeVideoId,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'exclude':
                            await content.setExcluded(
                              channelId: widget.channelId,
                              youtubeVideoId: video.youtubeVideoId,
                              excluded: !video.isExcluded,
                            );
                          case 'delete':
                            await _confirmDeleteVideo(video);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'exclude',
                          child: Text(
                            video.isExcluded
                                ? l10n.restoreVideo
                                : l10n.excludeVideo,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TupicColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TupicColors.borderSubtle),
      ),
      child: Text(
        text,
        style: const TextStyle(color: TupicColors.mutedText, height: 1.4),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 40,
        child: url == null
            ? const ColoredBox(
                color: TupicColors.selected,
                child: Icon(Icons.play_arrow, size: 18),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: TupicColors.selected,
                  child: Icon(Icons.play_arrow, size: 18),
                ),
              ),
      ),
    );
  }
}
