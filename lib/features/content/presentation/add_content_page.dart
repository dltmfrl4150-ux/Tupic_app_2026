import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../core/utils/open_youtube.dart';
import '../../../core/utils/title_sort.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/content_enums.dart';
import '../../../shared/models/playlist_fetch_models.dart';
import '../../../shared/models/youtube_url_parse_result.dart';
import '../../../shared/repositories/content_repository.dart';
import 'content_controller.dart';

enum _ContentTab { video, playlist, creator }

enum _PreviewSort { titleAsc, titleDesc, newest, oldest }

class AddContentPage extends StatefulWidget {
  const AddContentPage({super.key, required this.channelId});

  final String channelId;

  @override
  State<AddContentPage> createState() => _AddContentPageState();
}

class _AddContentPageState extends State<AddContentPage> {
  final _urlController = TextEditingController();
  _ContentTab _tab = _ContentTab.video;
  YoutubeUrlParseResult? _parsed;
  String? _errorText;
  bool _busy = false;
  bool _chooseVideo = true;

  CreatorImportMode _importMode = CreatorImportMode.recent30;
  _PreviewSort _previewSort = _PreviewSort.newest;

  PlaylistVideoItem? _singlePreview;
  ResolvedYoutubeChannel? _resolvedChannel;
  String? _previewTitle;
  String? _previewThumb;
  List<PlaylistVideoItem> _previewVideos = const [];
  final Set<String> _selectedIds = {};
  bool _hasMore = false;
  bool _truncated = false;
  String? _activePlaylistId;
  String? _activeOriginalUrl;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _clearPreview() {
    _singlePreview = null;
    _resolvedChannel = null;
    _previewTitle = null;
    _previewThumb = null;
    _previewVideos = const [];
    _selectedIds.clear();
    _hasMore = false;
    _truncated = false;
    _activePlaylistId = null;
    _activeOriginalUrl = null;
  }

  void _syncTabFromParsed(YoutubeUrlParseResult result) {
    if (result is YoutubeParsedVideo ||
        (result is YoutubeParsedAmbiguousWatchPlaylist && _chooseVideo)) {
      _tab = _ContentTab.video;
    } else if (result is YoutubeParsedPlaylist ||
        (result is YoutubeParsedAmbiguousWatchPlaylist && !_chooseVideo)) {
      _tab = _ContentTab.playlist;
    } else if (result is YoutubeParsedCreator) {
      _tab = _ContentTab.creator;
    }
  }

  YoutubeUrlParseResult? _effectiveParsed(ContentController content) {
    var parsed = _parsed ?? content.parseUrl(_urlController.text);
    if (parsed is YoutubeParsedAmbiguousWatchPlaylist) {
      parsed = _chooseVideo
          ? YoutubeParsedVideo(
              videoId: parsed.videoId,
              originalUrl: parsed.originalUrl,
            )
          : YoutubeParsedPlaylist(
              playlistId: parsed.playlistId,
              originalUrl: parsed.originalUrl,
              videoId: parsed.videoId,
            );
    }
    return parsed;
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) return;
    setState(() {
      _urlController.text = text.trim();
      _parsed = null;
      _errorText = null;
      _clearPreview();
    });
  }

  Future<void> _openYoutube() async {
    final l10n = AppLocalizations.of(context);
    final opened = await openYoutube();
    if (!mounted) return;
    if (!opened) setState(() => _errorText = l10n.openYoutubeFailed);
  }

  String _mapApiError(AppLocalizations l10n, YoutubeApiException error) {
    return switch (error.code) {
      'connection_failed' || 'timeout' || 'proxy_disabled' =>
        l10n.contentProxyConnectionFailed,
      'quota_exceeded' || 'daily_limit' => l10n.contentProxyQuotaExceeded,
      'channel_not_found' || 'invalid_channel' || 'uploads_unavailable' =>
        l10n.contentCreatorResolveFailed,
      _ => l10n.contentProxyVerifyFailed,
    };
  }

  List<PlaylistVideoItem> _sortedPreview() {
    final list = [..._previewVideos];
    switch (_previewSort) {
      case _PreviewSort.titleAsc:
        list.sort((a, b) => compareNaturalTitles(a.title, b.title));
      case _PreviewSort.titleDesc:
        list.sort((a, b) => compareNaturalTitles(b.title, a.title));
      case _PreviewSort.newest:
        list.sort((a, b) {
          final at = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bt = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bt.compareTo(at);
        });
      case _PreviewSort.oldest:
        list.sort((a, b) {
          final at = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bt = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return at.compareTo(bt);
        });
    }
    return list;
  }

  Future<void> _confirmContent() async {
    final l10n = AppLocalizations.of(context);
    final content = ContentScope.of(context);
    final rawParsed = content.parseUrl(_urlController.text);
    if (rawParsed is YoutubeUrlParseFailure) {
      setState(() {
        _parsed = rawParsed;
        _errorText = switch (rawParsed.reason) {
          YoutubeUrlParseFailureReason.empty => l10n.contentUrlEmpty,
          YoutubeUrlParseFailureReason.unsupportedHost =>
            l10n.contentUrlUnsupportedHost,
          YoutubeUrlParseFailureReason.redirectNotFollowed =>
            l10n.contentUrlRedirectBlocked,
          _ => l10n.contentUrlInvalid,
        };
        _clearPreview();
      });
      return;
    }

    setState(() {
      _parsed = rawParsed;
      _errorText = null;
      _syncTabFromParsed(rawParsed);
      _busy = true;
      _clearPreview();
    });

    try {
      final parsed = _effectiveParsed(content);
      if (parsed is YoutubeParsedVideo) {
        final meta = await content.previewSingleVideo(
          channelId: widget.channelId,
          youtubeVideoId: parsed.videoId,
        );
        if (!mounted) return;
        setState(() {
          _singlePreview = meta;
          _previewTitle = meta.title;
          _previewThumb = meta.thumbnailUrl;
          _activeOriginalUrl = parsed.originalUrl;
          _tab = _ContentTab.video;
        });
      } else if (parsed is YoutubeParsedPlaylist) {
        final remote = await content.previewPlaylist(
          channelId: widget.channelId,
          playlistId: parsed.playlistId,
          maxVideos: 50,
          forceRefresh: true,
        );
        if (!mounted) return;
        setState(() {
          _previewVideos = remote.videos;
          _selectedIds
            ..clear()
            ..addAll(remote.videos.map((v) => v.youtubeVideoId));
          _hasMore = remote.hasMore;
          _truncated = remote.truncatedByLimit;
          _previewTitle = 'Playlist';
          _activePlaylistId = parsed.playlistId;
          _activeOriginalUrl = parsed.originalUrl;
          _tab = _ContentTab.playlist;
        });
      } else if (parsed is YoutubeParsedCreator) {
        final resolved = await content.resolveCreatorChannel(
          channelId: parsed.channelId,
          handle: parsed.handle,
          username: parsed.username,
          customName: parsed.customName,
        );
        final maxVideos = _importMode == CreatorImportMode.recent30 ? 30 : 50;
        final remote = await content.previewPlaylist(
          channelId: widget.channelId,
          playlistId: resolved.uploadsPlaylistId,
          maxVideos: maxVideos,
          forceRefresh: true,
        );
        if (!mounted) return;
        setState(() {
          _resolvedChannel = resolved;
          _previewTitle = resolved.title;
          _previewThumb = resolved.thumbnailUrl;
          _previewVideos = remote.videos;
          _selectedIds
            ..clear()
            ..addAll(
              _importMode == CreatorImportMode.manual
                  ? <String>{}
                  : remote.videos.map((v) => v.youtubeVideoId),
            );
          _hasMore = remote.hasMore || _importMode == CreatorImportMode.all;
          _truncated = remote.truncatedByLimit;
          _activePlaylistId = resolved.uploadsPlaylistId;
          _activeOriginalUrl = parsed.originalUrl;
          _tab = _ContentTab.creator;
        });
      } else if (rawParsed is YoutubeParsedAmbiguousWatchPlaylist) {
        // Wait for user choice; still show ambiguous UI.
        setState(() {});
      }
    } on AgeRestrictedVideoException {
      if (!mounted) return;
      setState(() => _errorText = l10n.contentAgeRestrictedBlocked);
    } on VideoVerificationFailedException {
      if (!mounted) return;
      setState(() => _errorText = l10n.contentVideoVerificationFailed);
    } on YoutubeApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorText = _mapApiError(l10n, error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = l10n.errorTitle);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadMoreCreatorOrPlaylist() async {
    final playlistId = _activePlaylistId;
    if (playlistId == null || _busy) return;
    final l10n = AppLocalizations.of(context);
    final content = ContentScope.of(context);
    setState(() => _busy = true);
    try {
      final nextMax = (_previewVideos.length + 50).clamp(50, 500);
      final remote = await content.previewPlaylist(
        channelId: widget.channelId,
        playlistId: playlistId,
        maxVideos: nextMax,
        forceRefresh: true,
      );
      if (!mounted) return;
      final known = _previewVideos.map((v) => v.youtubeVideoId).toSet();
      final added = remote.videos
          .where((v) => !known.contains(v.youtubeVideoId))
          .toList();
      setState(() {
        _previewVideos = [..._previewVideos, ...added];
        if (_importMode != CreatorImportMode.manual) {
          _selectedIds.addAll(added.map((v) => v.youtubeVideoId));
        }
        _hasMore = remote.hasMore;
        _truncated = remote.truncatedByLimit;
      });
    } on YoutubeApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorText = _mapApiError(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addSingle() async {
    final l10n = AppLocalizations.of(context);
    final content = ContentScope.of(context);
    final meta = _singlePreview;
    final parsed = _effectiveParsed(content);
    if (meta == null || parsed is! YoutubeParsedVideo) return;
    setState(() {
      _busy = true;
      _errorText = null;
    });
    try {
      await content.addPreviewedVideo(
        channelId: widget.channelId,
        originalUrl: parsed.originalUrl,
        youtubeVideoId: parsed.videoId,
        meta: meta,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DuplicateVideoException {
      if (!mounted) return;
      setState(() => _errorText = l10n.contentDuplicateVideo);
    } on VideoLimitExceededException catch (error) {
      if (!mounted) return;
      setState(() => _errorText = l10n.contentVideoLimit(error.maxVideos));
    } on AgeRestrictedVideoException {
      if (!mounted) return;
      setState(() => _errorText = l10n.contentAgeRestrictedBlocked);
    } on YoutubeApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorText = _mapApiError(l10n, error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = l10n.errorTitle);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addSelected() async {
    final l10n = AppLocalizations.of(context);
    final content = ContentScope.of(context);
    final selected = _previewVideos
        .where((v) => _selectedIds.contains(v.youtubeVideoId))
        .toList(growable: false);
    if (selected.isEmpty) {
      setState(() => _errorText = l10n.contentNothingSelected);
      return;
    }
    setState(() {
      _busy = true;
      _errorText = null;
    });
    try {
      final isCreator = _tab == _ContentTab.creator;
      final parsed = _effectiveParsed(content);
      final report = await content.importSelectedVideos(
        channelId: widget.channelId,
        sourceType: isCreator
            ? ContentSourceType.creator
            : ContentSourceType.playlist,
        originalUrl: _activeOriginalUrl ??
            (parsed is YoutubeParsedPlaylist
                ? parsed.originalUrl
                : parsed is YoutubeParsedCreator
                ? parsed.originalUrl
                : ''),
        displayName: _previewTitle ??
            (isCreator
                ? (_resolvedChannel?.title ?? 'Creator')
                : 'Playlist'),
        selected: selected,
        youtubePlaylistId: _activePlaylistId,
        youtubeChannelId: _resolvedChannel?.channelId ??
            (parsed is YoutubeParsedCreator ? parsed.channelId : null),
        youtubeHandle: parsed is YoutubeParsedCreator ? parsed.handle : null,
        youtubeUsername:
            parsed is YoutubeParsedCreator ? parsed.username : null,
        youtubeCustomName:
            parsed is YoutubeParsedCreator ? parsed.customName : null,
        importMode: _importMode,
        hasMoreOnYoutube: _hasMore,
        truncatedByLimit: _truncated,
      );
      if (!mounted) return;
      final omitted = report.omittedByLimitCount;
      final message = omitted > 0
          ? l10n.contentImportPartial(
              report.importedCount,
              omitted,
            )
          : l10n.contentImportSuccess(report.importedCount);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop(true);
    } on DuplicateVideoException {
      if (!mounted) return;
      setState(() => _errorText = l10n.contentDuplicateVideo);
    } on VideoLimitExceededException catch (error) {
      if (!mounted) return;
      setState(() => _errorText = l10n.contentVideoLimit(error.maxVideos));
    } on AgeRestrictedVideoException {
      if (!mounted) return;
      setState(() => _errorText = l10n.contentAgeRestrictedBlocked);
    } on YoutubeApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorText = _mapApiError(l10n, error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = l10n.errorTitle);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parsed = _parsed;
    final sorted = _sortedPreview();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addContentTitle),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          SegmentedButton<_ContentTab>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: _ContentTab.video,
                label: Text(l10n.contentTypeVideo),
              ),
              ButtonSegment(
                value: _ContentTab.playlist,
                label: Text(l10n.contentTypePlaylist),
              ),
              ButtonSegment(
                value: _ContentTab.creator,
                label: Text(l10n.contentTypeCreator),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: _busy
                ? null
                : (values) {
                    if (values.isEmpty) return;
                    setState(() => _tab = values.first);
                  },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: l10n.addContentUrlHint,
              errorText: _errorText,
              suffixIcon: IconButton(
                tooltip: l10n.openYoutubeTooltip,
                onPressed: _busy ? null : _openYoutube,
                iconSize: 22,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: const EdgeInsets.all(10),
                icon: Icon(
                  Icons.smart_display_outlined,
                  color: TupicColors.accentViolet.withValues(alpha: 0.95),
                ),
              ),
            ),
            onChanged: (_) {
              if (_parsed != null || _errorText != null || _singlePreview != null) {
                setState(() {
                  _parsed = null;
                  _errorText = null;
                  _clearPreview();
                });
              }
            },
            onSubmitted: (_) => _confirmContent(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _paste,
                icon: const Icon(Icons.content_paste),
                label: Text(l10n.paste),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                key: const Key('confirm_content_button'),
                onPressed: _busy ? null : _confirmContent,
                child: Text(l10n.confirmContent),
              ),
            ],
          ),
          if (parsed is YoutubeParsedAmbiguousWatchPlaylist) ...[
            const SizedBox(height: 12),
            Text(
              l10n.contentAmbiguousTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            RadioGroup<bool>(
              groupValue: _chooseVideo,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _chooseVideo = value;
                  _clearPreview();
                });
              },
              child: Column(
                children: [
                  RadioListTile<bool>(
                    value: true,
                    title: Text(l10n.contentAmbiguousVideo),
                  ),
                  RadioListTile<bool>(
                    value: false,
                    title: Text(l10n.contentAmbiguousPlaylist),
                  ),
                ],
              ),
            ),
          ],
          if (_tab == _ContentTab.creator && _singlePreview == null) ...[
            const SizedBox(height: 12),
            Text(
              l10n.creatorImportModeLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.creatorImportRecent30),
                  selected: _importMode == CreatorImportMode.recent30,
                  onSelected: _busy
                      ? null
                      : (_) => setState(
                            () => _importMode = CreatorImportMode.recent30,
                          ),
                ),
                ChoiceChip(
                  label: Text(l10n.creatorImportAll),
                  selected: _importMode == CreatorImportMode.all,
                  onSelected: _busy
                      ? null
                      : (_) =>
                            setState(() => _importMode = CreatorImportMode.all),
                ),
                ChoiceChip(
                  label: Text(l10n.creatorImportManual),
                  selected: _importMode == CreatorImportMode.manual,
                  onSelected: _busy
                      ? null
                      : (_) => setState(
                            () => _importMode = CreatorImportMode.manual,
                          ),
                ),
              ],
            ),
          ],
          if (_busy) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_singlePreview != null) ...[
            const SizedBox(height: 16),
            _PreviewHeader(
              title: _previewTitle ?? _singlePreview!.title,
              subtitle: _singlePreview!.channelTitle,
              thumbUrl: _previewThumb ?? _singlePreview!.thumbnailUrl,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('add_single_video_button'),
              onPressed: _busy ? null : _addSingle,
              child: Text(l10n.addSingleVideo),
            ),
          ],
          if (_previewVideos.isNotEmpty) ...[
            const SizedBox(height: 16),
            if (_previewTitle != null || _previewThumb != null)
              _PreviewHeader(
                title: _previewTitle ?? '',
                subtitle: _resolvedChannel?.channelId,
                thumbUrl: _previewThumb,
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final sort in _PreviewSort.values)
                  ChoiceChip(
                    label: Text(switch (sort) {
                      _PreviewSort.titleAsc => l10n.previewSortTitleAsc,
                      _PreviewSort.titleDesc => l10n.previewSortTitleDesc,
                      _PreviewSort.newest => l10n.previewSortNewest,
                      _PreviewSort.oldest => l10n.previewSortOldest,
                    }),
                    selected: _previewSort == sort,
                    onSelected: (_) => setState(() => _previewSort = sort),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _selectedIds
                      ..clear()
                      ..addAll(_previewVideos.map((v) => v.youtubeVideoId));
                  }),
                  child: Text(l10n.selectAllVideos),
                ),
                TextButton(
                  onPressed: () => setState(_selectedIds.clear),
                  child: Text(l10n.clearVideoSelection),
                ),
              ],
            ),
            ...sorted.map((video) {
              final selected = _selectedIds.contains(video.youtubeVideoId);
              return CheckboxListTile(
                value: selected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedIds.add(video.youtubeVideoId);
                    } else {
                      _selectedIds.remove(video.youtubeVideoId);
                    }
                  });
                },
                secondary: _Thumb(url: video.thumbnailUrl),
                title: Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
            if (_hasMore)
              TextButton(
                onPressed: _busy ? null : _loadMoreCreatorOrPlaylist,
                child: Text(l10n.loadMoreVideos),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const Key('add_selected_videos_button'),
              onPressed: _busy ? null : _addSelected,
              child: Text(l10n.addSelectedVideos),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({
    required this.title,
    this.subtitle,
    this.thumbUrl,
  });

  final String title;
  final String? subtitle;
  final String? thumbUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TupicColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TupicColors.borderSubtle),
      ),
      child: Row(
        children: [
          _Thumb(url: thumbUrl, width: 72, height: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: TupicColors.primaryText,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
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
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url, this.width = 56, this.height = 36});

  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
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
