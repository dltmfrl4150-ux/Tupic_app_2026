import 'package:flutter/material.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../core/config/dev_api_config.dart';
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
          content: Text(l10n.deleteVideoBody(video.displayTitle)),
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

  Future<void> _editVideoTitle(ChannelVideo video) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: video.displayTitle);
    final result = await showDialog<_TitleEditResult>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.editVideoTitleTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.editVideoTitleLabel,
                  hintText: video.originalTitle ??
                      ChannelVideo.provisionalTitle(video.youtubeVideoId),
                ),
              ),
              if (video.originalTitle != null &&
                  video.originalTitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.originalVideoTitleHint(video.originalTitle!),
                  style: const TextStyle(
                    color: TupicColors.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (video.hasCustomTitle ||
                (video.originalTitle != null &&
                    video.originalTitle!.trim().isNotEmpty))
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, const _TitleEditResult.restore()),
                child: Text(l10n.restoreOriginalTitle),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                _TitleEditResult.save(controller.text),
              ),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null || !mounted) return;

    final customTitle = result.restore
        ? null
        : (result.value?.trim().isEmpty ?? true ? null : result.value);
    await ContentScope.of(context).updateVideoCustomTitle(
      channelId: widget.channelId,
      youtubeVideoId: video.youtubeVideoId,
      customTitle: customTitle,
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

  Future<void> _checkNewCreatorVideos(ContentSource source) async {
    final l10n = AppLocalizations.of(context);
    final content = ContentScope.of(context);
    try {
      var uploadsId = source.youtubePlaylistId;
      if (uploadsId == null || uploadsId.isEmpty) {
        final resolved = await content.resolveCreatorChannel(
          channelId: source.youtubeChannelId,
          handle: source.youtubeHandle,
          username: source.youtubeUsername,
          customName: source.youtubeCustomName,
        );
        uploadsId = resolved.uploadsPlaylistId;
      }
      final news = await content.previewNewCreatorVideos(
        channelId: widget.channelId,
        sourceId: source.id,
        uploadsPlaylistId: uploadsId,
        maxVideos: 30,
      );
      if (!mounted) return;
      if (news.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noNewCreatorVideos)),
        );
        return;
      }
      final selected = await showDialog<Set<String>>(
        context: context,
        builder: (context) {
          final picks = news.map((v) => v.youtubeVideoId).toSet();
          return StatefulBuilder(
            builder: (context, setLocal) {
              return AlertDialog(
                title: Text(l10n.checkNewVideos),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final video in news)
                        CheckboxListTile(
                          value: picks.contains(video.youtubeVideoId),
                          title: Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onChanged: (value) {
                            setLocal(() {
                              if (value == true) {
                                picks.add(video.youtubeVideoId);
                              } else {
                                picks.remove(video.youtubeVideoId);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, picks),
                    child: Text(l10n.addSelectedVideos),
                  ),
                ],
              );
            },
          );
        },
      );
      if (selected == null || selected.isEmpty || !mounted) return;
      final chosen =
          news.where((v) => selected.contains(v.youtubeVideoId)).toList();
      final report = await content.importSelectedVideos(
        channelId: widget.channelId,
        sourceType: ContentSourceType.creator,
        originalUrl: source.originalUrl,
        displayName: source.displayName,
        selected: chosen,
        existingSourceId: source.id,
        youtubePlaylistId: uploadsId,
        youtubeChannelId: source.youtubeChannelId,
        youtubeHandle: source.youtubeHandle,
        youtubeUsername: source.youtubeUsername,
        youtubeCustomName: source.youtubeCustomName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.contentImportSuccess(report.importedCount)),
        ),
      );
    } on YoutubeApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.isConnectionFailed
                ? l10n.localServerRequired
                : error.isQuotaExceeded
                ? l10n.quotaExceededMessage
                : l10n.contentCreatorResolveFailed,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorTitle)),
      );
    }
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
          report.excludedPrivateDeleted +
              report.excludedMissing +
              report.excludedVerificationFailed,
          report.excludedNotEmbeddable,
          report.duplicateCount,
        ),
      );
      if (report.excludedAgeRestricted > 0) {
        summary.write('\n');
        summary.write(
          l10n.playlistAgeRestrictedExcluded(report.excludedAgeRestricted),
        );
      }
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
                    final isCreator =
                        source.sourceType == ContentSourceType.creator;
                    final canFetch = isPlaylist &&
                        source.youtubePlaylistId != null &&
                        !fetching;
                    final showRetry = isPlaylist &&
                        (source.importStatus == ImportStatus.failed ||
                            source.importStatus == ImportStatus.pendingFetch ||
                            source.importStatus ==
                                ImportStatus.partiallyFetched ||
                            source.importStatus == ImportStatus.fetched);
                    final linkedCount = content
                        .videosFor(widget.channelId)
                        .where((v) => v.sourceIds.contains(source.id))
                        .length;
                    final statusLine =
                        '${_sourceTypeLabel(l10n, source.sourceType)} · ${_statusLabel(l10n, source, fetching: fetching)}';
                    final isVideo =
                        source.sourceType == ContentSourceType.video;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: TupicColors.card,
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: TupicColors.borderSubtle,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              14,
                              isVideo ? 10 : 12,
                              4,
                              isVideo ? 10 : 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        source.displayName,
                                        maxLines: isVideo ? 2 : 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        statusLine,
                                        style: const TextStyle(
                                          color: TupicColors.mutedText,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (isCreator) ...[
                                        if (source.youtubeChannelId != null)
                                          Text(
                                            source.youtubeChannelId!,
                                            style: const TextStyle(
                                              color: TupicColors.mutedText,
                                              fontSize: 11,
                                            ),
                                          ),
                                        Text(
                                          l10n.playlistFetchedCount(
                                            linkedCount,
                                          ),
                                          style: const TextStyle(
                                            color: TupicColors.mutedText,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                      if (!isVideo &&
                                          source.lastFetchedAt != null)
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
                                      if (!isVideo &&
                                          source.lastErrorMessage != null &&
                                          source
                                              .lastErrorMessage!.isNotEmpty)
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
                                ),
                                if (isCreator)
                                  IconButton(
                                    tooltip: l10n.checkNewVideos,
                                    icon: const Icon(
                                      Icons.new_releases_outlined,
                                    ),
                                    onPressed: fetching
                                        ? null
                                        : () =>
                                            _checkNewCreatorVideos(source),
                                  ),
                                if (canFetch && showRetry)
                                  IconButton(
                                    tooltip: source.importStatus ==
                                                ImportStatus.failed ||
                                            source.importStatus ==
                                                ImportStatus
                                                    .partiallyFetched ||
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
                                                ? Icons
                                                    .cloud_download_outlined
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
                                  onPressed: () =>
                                      _confirmDeleteSource(source),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                if (!DevApiConfig.isPlaylistFetchAvailable &&
                    sources.any(
                      (s) =>
                          s.sourceType == ContentSourceType.creator ||
                          s.sourceType == ContentSourceType.playlist,
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
                      video.displayTitle,
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
                          case 'edit_title':
                            await _editVideoTitle(video);
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
                          value: 'edit_title',
                          child: Text(l10n.editVideoTitle),
                        ),
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

class _TitleEditResult {
  const _TitleEditResult.save(this.value) : restore = false;
  const _TitleEditResult.restore()
      : value = null,
        restore = true;

  final String? value;
  final bool restore;
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
