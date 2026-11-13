import 'package:flutter/material.dart';

import '../../../core/config/dev_api_config.dart';
import '../../../core/constants/plan_limits.dart';
import '../../../core/utils/playback_queue_builder.dart';
import '../../../core/utils/youtube_url_parser.dart';
import '../../../shared/models/channel_video.dart';
import '../../../shared/models/content_enums.dart';
import '../../../shared/models/content_source.dart';
import '../../../shared/models/play_order.dart';
import '../../../shared/models/playlist_fetch_models.dart';
import '../../../shared/models/youtube_url_parse_result.dart';
import '../../channels/presentation/channels_controller.dart';
import '../../../shared/repositories/channel_repository.dart';
import '../../../shared/repositories/content_repository.dart';
import '../data/http_youtube_playlist_provider.dart';
import '../data/playlist_video_fetcher.dart';

class ContentController extends ChangeNotifier {
  ContentController({
    required ContentRepository contentRepository,
    required ChannelRepository channelRepository,
    ChannelsController? channelsController,
    YoutubeUrlParser parser = const YoutubeUrlParser(),
    PlaybackQueueBuilder queueBuilder = const PlaybackQueueBuilder(),
    PlaylistVideoFetcher? playlistFetcher,
  }) : _contentRepository = contentRepository,
       _channelRepository = channelRepository,
       _channelsController = channelsController,
       _parser = parser,
       _queueBuilder = queueBuilder,
       _playlistFetcher = playlistFetcher;

  final ContentRepository _contentRepository;
  final ChannelRepository _channelRepository;
  final ChannelsController? _channelsController;
  final YoutubeUrlParser _parser;
  final PlaybackQueueBuilder _queueBuilder;

  /// Nullable so Hot Reload cannot leave a non-null field as runtime null.
  /// [playlistFetcher] always resolves to a live instance.
  PlaylistVideoFetcher? _playlistFetcher;

  /// Always returns a concrete fetcher; creates the default HTTP provider if needed.
  PlaylistVideoFetcher get playlistFetcher {
    final existing = _playlistFetcher;
    if (existing != null) return existing;
    final created = HttpYoutubePlaylistProvider.create();
    _playlistFetcher = created;
    return created;
  }

  final Map<String, List<ContentSource>> _sourcesByChannel = {};
  final Map<String, List<ChannelVideo>> _videosByChannel = {};
  final Map<String, int> _activeCounts = {};
  final Set<String> _fetchingSourceIds = {};
  bool _loading = false;
  String? _errorMessage;
  bool _dataError = false;

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  bool get dataError => _dataError;
  bool isFetchingSource(String sourceId) => _fetchingSourceIds.contains(sourceId);

  List<ContentSource> sourcesFor(String channelId) =>
      _sourcesByChannel[channelId] ?? const [];

  List<ChannelVideo> videosFor(String channelId) =>
      _videosByChannel[channelId] ?? const [];

  int activeCountFor(String channelId) => _activeCounts[channelId] ?? 0;

  int maxVideosPerChannel({required bool premium}) =>
      PlanLimits.maxVideosPerChannel(premium: premium);

  YoutubeUrlParseResult parseUrl(String raw) => _parser.parse(raw);

  List<ChannelVideo> buildQueue({
    required String channelId,
    required PlayOrder playOrder,
  }) {
    return _queueBuilder.build(
      sources: sourcesFor(channelId),
      videos: videosFor(channelId),
      playOrder: playOrder,
    );
  }

  Future<void> loadChannel(String channelId) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final sources =
          await _contentRepository.getSources(tupicChannelId: channelId);
      final videos =
          await _contentRepository.getVideos(tupicChannelId: channelId);
      final count = await _contentRepository.countActiveVideos(channelId);
      _sourcesByChannel[channelId] = sources;
      _videosByChannel[channelId] = videos;
      _activeCounts[channelId] = count;
      _dataError = false;
      await _syncChannelVideoCount(channelId, count);
    } catch (error) {
      _errorMessage = error.toString();
      _dataError = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCounts(Iterable<String> channelIds) async {
    for (final id in channelIds) {
      try {
        final count = await _contentRepository.countActiveVideos(id);
        _activeCounts[id] = count;
        await _syncChannelVideoCount(id, count);
      } catch (_) {
        // Keep previous count on failure.
      }
    }
    notifyListeners();
  }

  Future<ContentSource> addParsedContent({
    required String channelId,
    required YoutubeUrlParseResult parsed,
    required String displayName,
    CreatorImportMode importMode = CreatorImportMode.recent30,
    CreatorSortOrder sortOrder = CreatorSortOrder.newest,
    bool autoSyncEnabled = false,
  }) async {
    final ContentSource source;
    switch (parsed) {
      case YoutubeParsedVideo(:final videoId, :final originalUrl):
        final meta = await _assertSingleVideoAllowed(channelId, videoId);
        final originalTitle = _cleanOptionalTitle(meta?.title);
        final customTitle = _resolveCustomTitle(
          displayName: displayName,
          videoId: videoId,
          originalTitle: originalTitle,
        );
        source = await _contentRepository.addVideoSource(
          tupicChannelId: channelId,
          originalUrl: originalUrl,
          youtubeVideoId: videoId,
          displayName: displayName,
          originalTitle: originalTitle,
          customTitle: customTitle,
          thumbnailUrl: meta?.thumbnailUrl,
        );
      case YoutubeParsedPlaylist(:final playlistId, :final originalUrl):
        source = await _contentRepository.addPlaylistSource(
          tupicChannelId: channelId,
          originalUrl: originalUrl,
          youtubePlaylistId: playlistId,
          displayName: displayName,
        );
      case YoutubeParsedCreator(
          :final originalUrl,
          channelId: final youtubeChannelId,
          :final handle,
          :final username,
          :final customName,
        ):
        source = await _contentRepository.addCreatorSource(
          tupicChannelId: channelId,
          originalUrl: originalUrl,
          displayName: displayName,
          youtubeChannelId: youtubeChannelId,
          youtubeHandle: handle,
          youtubeUsername: username,
          youtubeCustomName: customName,
          importMode: importMode,
          sortOrder: sortOrder,
          autoSyncEnabled: autoSyncEnabled,
        );
      case YoutubeParsedAmbiguousWatchPlaylist():
        throw StateError('Ambiguous URL requires an explicit choice');
      case YoutubeUrlParseFailure():
        throw StateError('Invalid YouTube URL');
    }
    await loadChannel(channelId);
    return source;
  }

  Future<ContentSource> updateCreatorOptions({
    required String channelId,
    required String sourceId,
    CreatorImportMode? importMode,
    CreatorSortOrder? sortOrder,
    bool? autoSyncEnabled,
  }) async {
    final source = await _contentRepository.updateCreatorOptions(
      sourceId: sourceId,
      importMode: importMode,
      sortOrder: sortOrder,
      autoSyncEnabled: autoSyncEnabled,
    );
    await loadChannel(channelId);
    return source;
  }

  Future<void> reorderVideos({
    required String channelId,
    required List<String> youtubeVideoIdsInOrder,
  }) async {
    await _contentRepository.reorderVideos(
      tupicChannelId: channelId,
      youtubeVideoIdsInOrder: youtubeVideoIdsInOrder,
    );
    await loadChannel(channelId);
  }

  Future<void> setExcluded({
    required String channelId,
    required String youtubeVideoId,
    required bool excluded,
  }) async {
    await _contentRepository.setVideoExcluded(
      tupicChannelId: channelId,
      youtubeVideoId: youtubeVideoId,
      excluded: excluded,
    );
    await loadChannel(channelId);
  }

  Future<void> updateVideoCustomTitle({
    required String channelId,
    required String youtubeVideoId,
    String? customTitle,
  }) async {
    await _contentRepository.updateVideoCustomTitle(
      tupicChannelId: channelId,
      youtubeVideoId: youtubeVideoId,
      customTitle: customTitle,
    );
    await loadChannel(channelId);
  }

  Future<void> deleteVideo({
    required String channelId,
    required String youtubeVideoId,
  }) async {
    await _contentRepository.deleteVideo(
      tupicChannelId: channelId,
      youtubeVideoId: youtubeVideoId,
    );
    await loadChannel(channelId);
  }

  Future<SourceDeleteImpact> deleteSource({
    required String channelId,
    required String sourceId,
  }) async {
    final impact = await _contentRepository.deleteSource(sourceId);
    await loadChannel(channelId);
    return impact;
  }

  Future<void> deleteAllForChannel(String channelId) async {
    await _contentRepository.deleteAllForChannel(channelId);
    _sourcesByChannel.remove(channelId);
    _videosByChannel.remove(channelId);
    _activeCounts.remove(channelId);
    notifyListeners();
  }

  /// Fetches playlist items via the local proxy and imports within free limits.
  Future<PlaylistImportReport> fetchPlaylistVideos({
    required String channelId,
    required String sourceId,
    bool forceRefresh = false,
  }) async {
    if (!DevApiConfig.isPlaylistFetchAvailable) {
      throw const YoutubeApiException(
        code: 'proxy_disabled',
        message:
            'Playlist fetch is only available in debug builds with the local server.',
      );
    }

    final allSources = await _contentRepository.getSources(
      tupicChannelId: channelId,
    );
    ContentSource? source;
    for (final item in allSources) {
      if (item.id == sourceId) {
        source = item;
        break;
      }
    }

    if (source == null ||
        source.sourceType != ContentSourceType.playlist ||
        source.youtubePlaylistId == null ||
        source.youtubePlaylistId!.isEmpty) {
      throw ContentSourceNotFoundException(sourceId);
    }

    if (_fetchingSourceIds.contains(sourceId)) {
      throw const YoutubeApiException(
        code: 'already_fetching',
        message: 'This playlist is already being fetched.',
      );
    }

    _fetchingSourceIds.add(sourceId);
    await _contentRepository.updateSourceImportState(
      sourceId: sourceId,
      importStatus: ImportStatus.fetching,
      clearLastError: true,
    );
    await loadChannel(channelId);

    try {
      final isKidsChannel = await _isKidsChannel(channelId);
      final existingLinked = videosFor(channelId)
          .where((v) => v.sourceIds.contains(sourceId))
          .toList(growable: false);
      final localPlaceholderIds = {
        for (final video in existingLinked)
          if (isPlaceholderVideoTitle(video.title)) video.youtubeVideoId,
      };

      final active = activeCountFor(channelId);
      final max = maxVideosPerChannel(premium: PlanLimits.isPremium);
      // Placeholder rows should not consume the free 100 slots when refreshing.
      final remaining = (max - (active - localPlaceholderIds.length)).clamp(
        0,
        max,
      );

      late final PlaylistFetchResult remote;
      if (remaining > 0) {
        remote = await playlistFetcher.fetchPlaylist(
          playlistId: source.youtubePlaylistId!,
          maxVideos: remaining,
          forceRefresh: forceRefresh,
        );
      } else if (existingLinked.isNotEmpty) {
        // At capacity: still re-validate/prune existing unplayable rows.
        remote = PlaylistFetchResult(
          playlistId: source.youtubePlaylistId!,
          videos: const [],
          hasMore: false,
          truncatedByLimit: true,
          skippedInvalid: 0,
        );
      } else {
        throw VideoLimitExceededException(max);
      }

      final ageRestrictedIdSet = <String>{
        ...remote.ageRestrictedIds,
        for (final item in remote.ageRestrictedVideos) item.youtubeVideoId,
      };

      // Kids: allowed only. General: allowed + age-restricted metadata.
      final importItems = <PlaylistVideoItem>[
        ...remote.videos,
        if (!isKidsChannel) ...remote.ageRestrictedVideos,
      ];

      final playableOrAcceptedIds = {
        for (final item in importItems) item.youtubeVideoId,
      };
      final unplayableIds = <String>{
        ...remote.excludedVideoIds,
        ...localPlaceholderIds,
      };
      // General channels may keep age-restricted rows; do not prune them.
      if (!isKidsChannel) {
        unplayableIds.removeAll(ageRestrictedIdSet);
      }

      // Re-validate existing linked videos not confirmed in this fetch.
      final needsValidation = existingLinked
          .map((v) => v.youtubeVideoId)
          .where(
            (id) =>
                !playableOrAcceptedIds.contains(id) &&
                !unplayableIds.contains(id),
          )
          .toList(growable: false);
      var extraPrivate = 0;
      var extraNotEmbeddable = 0;
      var extraMissing = 0;
      var extraAgeRestricted = 0;
      var extraVerificationFailed = 0;
      if (needsValidation.isNotEmpty) {
        final validation = await playlistFetcher.validateVideoIds(
          needsValidation,
        );
        unplayableIds.addAll(validation.unplayableIds);
        if (!isKidsChannel) {
          unplayableIds.removeAll(validation.ageRestrictedIds);
        }
        extraPrivate = validation.excludedPrivateDeleted;
        extraNotEmbeddable = validation.excludedNotEmbeddable;
        extraMissing = validation.excludedMissing;
        extraAgeRestricted = isKidsChannel
            ? validation.excludedAgeRestricted
            : 0;
        extraVerificationFailed = validation.excludedVerificationFailed;
      }

      final report = await _contentRepository.importPlaylistVideos(
        sourceId: sourceId,
        items: importItems,
        truncatedByLimit: remote.truncatedByLimit || remaining < max,
        hasMoreOnYoutube: remote.hasMore,
        skippedInvalidCount: remote.skippedInvalid,
        excludedPrivateDeleted:
            remote.excludedPrivateDeleted + extraPrivate,
        excludedNotEmbeddable:
            remote.excludedNotEmbeddable + extraNotEmbeddable,
        excludedMissing: remote.excludedMissing + extraMissing,
        excludedAgeRestricted: isKidsChannel
            ? remote.excludedAgeRestricted + extraAgeRestricted
            : 0,
        excludedVerificationFailed:
            remote.excludedVerificationFailed + extraVerificationFailed,
        unplayableVideoIds: unplayableIds,
      );
      await loadChannel(channelId);
      return report;
    } on YoutubeApiException catch (error) {
      await _markFetchFailed(channelId, sourceId, error.message);
      rethrow;
    } on VideoLimitExceededException catch (error) {
      await _markFetchFailed(channelId, sourceId, error.toString());
      rethrow;
    } catch (error, stack) {
      debugPrint('Playlist fetch failed: $error');
      debugPrintStack(stackTrace: stack);
      final wrapped = YoutubeApiException(
        code: 'unexpected',
        message: _userFacingFetchError(error),
      );
      await _markFetchFailed(channelId, sourceId, wrapped.message);
      throw wrapped;
    } finally {
      _fetchingSourceIds.remove(sourceId);
      notifyListeners();
    }
  }

  Future<bool> _isKidsChannel(String channelId) async {
    final channel = await _channelRepository.getChannel(channelId);
    // Missing channel should not silently allow restricted content.
    return channel?.isKidsChannel ?? true;
  }

  /// Preview a single video (validate only — does not save).
  Future<PlaylistVideoItem> previewSingleVideo({
    required String channelId,
    required String youtubeVideoId,
  }) async {
    if (!DevApiConfig.isPlaylistFetchAvailable) {
      throw const VideoVerificationFailedException();
    }
    final isKidsChannel = await _isKidsChannel(channelId);
    final validation = await playlistFetcher.validateVideoIds([youtubeVideoId]);
    if (validation.ageRestrictedIds.contains(youtubeVideoId)) {
      if (isKidsChannel) {
        throw AgeRestrictedVideoException(youtubeVideoId);
      }
      final meta = validation.metaFor(youtubeVideoId);
      return meta ??
          PlaylistVideoItem(
            youtubeVideoId: youtubeVideoId,
            title: ChannelVideo.provisionalTitleEn(youtubeVideoId),
            position: 0,
          );
    }
    if (validation.playableIds.contains(youtubeVideoId)) {
      final meta = validation.metaFor(youtubeVideoId);
      return meta ??
          PlaylistVideoItem(
            youtubeVideoId: youtubeVideoId,
            title: ChannelVideo.provisionalTitleEn(youtubeVideoId),
            position: 0,
          );
    }
    throw VideoVerificationFailedException(youtubeVideoId);
  }

  /// Preview playlist videos without saving.
  Future<PlaylistFetchResult> previewPlaylist({
    required String channelId,
    required String playlistId,
    required int maxVideos,
    bool forceRefresh = false,
  }) async {
    if (!DevApiConfig.isPlaylistFetchAvailable) {
      throw const YoutubeApiException(
        code: 'proxy_disabled',
        message: 'Local YouTube proxy is unavailable.',
      );
    }
    final isKidsChannel = await _isKidsChannel(channelId);
    final remote = await playlistFetcher.fetchPlaylist(
      playlistId: playlistId,
      maxVideos: maxVideos,
      forceRefresh: forceRefresh,
    );
    if (isKidsChannel) {
      return remote;
    }
    // General: surface age-restricted rows as selectable candidates.
    return PlaylistFetchResult(
      playlistId: remote.playlistId,
      videos: [...remote.videos, ...remote.ageRestrictedVideos],
      hasMore: remote.hasMore,
      truncatedByLimit: remote.truncatedByLimit,
      skippedInvalid: remote.skippedInvalid,
      excludedPrivateDeleted: remote.excludedPrivateDeleted,
      excludedNotEmbeddable: remote.excludedNotEmbeddable,
      excludedMissing: remote.excludedMissing,
      excludedAgeRestricted: 0,
      excludedVerificationFailed: remote.excludedVerificationFailed,
      excludedVideoIds: remote.excludedVideoIds,
      ageRestrictedVideos: remote.ageRestrictedVideos,
      ageRestrictedIds: remote.ageRestrictedIds,
      fromCache: remote.fromCache,
    );
  }

  Future<ResolvedYoutubeChannel> resolveCreatorChannel({
    String? channelId,
    String? handle,
    String? username,
    String? customName,
  }) {
    return playlistFetcher.resolveChannel(
      channelId: channelId,
      handle: handle,
      username: username,
      customName: customName,
    );
  }

  /// Registers a previously previewed single video (no second validate if [meta] given).
  Future<ContentSource> addPreviewedVideo({
    required String channelId,
    required String originalUrl,
    required String youtubeVideoId,
    required PlaylistVideoItem meta,
    String displayName = '',
  }) async {
    final originalTitle = _cleanOptionalTitle(meta.title);
    final customTitle = _resolveCustomTitle(
      displayName: displayName,
      videoId: youtubeVideoId,
      originalTitle: originalTitle,
    );
    final source = await _contentRepository.addVideoSource(
      tupicChannelId: channelId,
      originalUrl: originalUrl,
      youtubeVideoId: youtubeVideoId,
      displayName: displayName.isNotEmpty
          ? displayName
          : (originalTitle ?? ChannelVideo.provisionalTitle(youtubeVideoId)),
      originalTitle: originalTitle,
      customTitle: customTitle,
      thumbnailUrl: meta.thumbnailUrl,
    );
    await loadChannel(channelId);
    return source;
  }

  /// Creates playlist/creator source (if needed) and imports only [selected].
  Future<PlaylistImportReport> importSelectedVideos({
    required String channelId,
    required ContentSourceType sourceType,
    required String originalUrl,
    required String displayName,
    required List<PlaylistVideoItem> selected,
    String? youtubePlaylistId,
    String? youtubeChannelId,
    String? youtubeHandle,
    String? youtubeUsername,
    String? youtubeCustomName,
    String? existingSourceId,
    CreatorImportMode importMode = CreatorImportMode.recent30,
    bool hasMoreOnYoutube = false,
    bool truncatedByLimit = false,
  }) async {
    if (selected.isEmpty) {
      throw const YoutubeApiException(
        code: 'nothing_selected',
        message: 'No videos selected.',
      );
    }
    final isKidsChannel = await _isKidsChannel(channelId);
    var items = List<PlaylistVideoItem>.from(selected);
    if (isKidsChannel) {
      final ids = items.map((e) => e.youtubeVideoId).toList();
      final validation = await playlistFetcher.validateVideoIds(ids);
      final blocked = validation.ageRestrictedIds.toSet();
      items = items
          .where((e) => !blocked.contains(e.youtubeVideoId))
          .toList(growable: false);
      if (items.isEmpty) {
        throw AgeRestrictedVideoException(ids.first);
      }
    }

    late final ContentSource source;
    if (existingSourceId != null) {
      final all = await _contentRepository.getSources(tupicChannelId: channelId);
      ContentSource? found;
      for (final s in all) {
        if (s.id == existingSourceId) {
          found = s;
          break;
        }
      }
      if (found == null) throw ContentSourceNotFoundException(existingSourceId);
      source = found;
    } else if (sourceType == ContentSourceType.playlist) {
      source = await _contentRepository.addPlaylistSource(
        tupicChannelId: channelId,
        originalUrl: originalUrl,
        youtubePlaylistId: youtubePlaylistId!,
        displayName: displayName,
      );
    } else if (sourceType == ContentSourceType.creator) {
      source = await _contentRepository.addCreatorSource(
        tupicChannelId: channelId,
        originalUrl: originalUrl,
        displayName: displayName,
        youtubeChannelId: youtubeChannelId,
        youtubeHandle: youtubeHandle,
        youtubeUsername: youtubeUsername,
        youtubeCustomName: youtubeCustomName,
        youtubePlaylistId: youtubePlaylistId,
        importMode: importMode,
        autoSyncEnabled: false,
      );
    } else {
      throw StateError('Unsupported source type for multi import');
    }

    final report = await _contentRepository.importPlaylistVideos(
      sourceId: source.id,
      items: items,
      truncatedByLimit: truncatedByLimit,
      hasMoreOnYoutube: hasMoreOnYoutube,
      skippedInvalidCount: 0,
    );
    await loadChannel(channelId);
    return report;
  }

  /// Fetches creator uploads and returns only videos not already linked to [sourceId].
  Future<List<PlaylistVideoItem>> previewNewCreatorVideos({
    required String channelId,
    required String sourceId,
    required String uploadsPlaylistId,
    int maxVideos = 30,
  }) async {
    final remote = await previewPlaylist(
      channelId: channelId,
      playlistId: uploadsPlaylistId,
      maxVideos: maxVideos,
      forceRefresh: true,
    );
    final existing = videosFor(channelId)
        .where((v) => v.sourceIds.contains(sourceId))
        .map((v) => v.youtubeVideoId)
        .toSet();
    return remote.videos
        .where((v) => !existing.contains(v.youtubeVideoId))
        .toList(growable: false);
  }

  /// Validates a single video via the local proxy before registration.
  /// Age-restricted: blocked on kids channels only; allowed on general.
  /// Does not mutate SharedPreferences on failure.
  /// Returns metadata from the same videos.list response (no extra quota).
  Future<PlaylistVideoItem?> _assertSingleVideoAllowed(
    String channelId,
    String youtubeVideoId,
  ) async {
    if (!DevApiConfig.isPlaylistFetchAvailable) {
      throw const VideoVerificationFailedException();
    }
    final isKidsChannel = await _isKidsChannel(channelId);
    final validation = await playlistFetcher.validateVideoIds([youtubeVideoId]);
    if (validation.ageRestrictedIds.contains(youtubeVideoId)) {
      if (isKidsChannel) {
        throw AgeRestrictedVideoException(youtubeVideoId);
      }
      // General channel: age-restricted may still fail in the embedded player.
      return validation.metaFor(youtubeVideoId);
    }
    if (validation.playableIds.contains(youtubeVideoId)) {
      return validation.metaFor(youtubeVideoId);
    }
    // Private, deleted, non-embeddable, missing, or incomplete — not labeled
    // as age-restricted.
    throw VideoVerificationFailedException(youtubeVideoId);
  }

  static String? _cleanOptionalTitle(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  /// Treat empty / provisional / same-as-original display names as no custom.
  static String? _resolveCustomTitle({
    required String displayName,
    required String videoId,
    String? originalTitle,
  }) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return null;
    if (ChannelVideo.isProvisionalTitleText(trimmed, videoId)) return null;
    if (originalTitle != null && trimmed == originalTitle.trim()) return null;
    return trimmed;
  }

  Future<void> _markFetchFailed(
    String channelId,
    String sourceId,
    String message,
  ) async {
    await _contentRepository.updateSourceImportState(
      sourceId: sourceId,
      importStatus: ImportStatus.failed,
      lastErrorMessage: message,
    );
    await loadChannel(channelId);
  }

  static String _userFacingFetchError(Object error) {
    final text = error.toString();
    if (text.contains('HttpYoutubePlaylistProvider') ||
        text.contains('is not a subtype') ||
        text.contains('Null')) {
      return 'Playlist provider failed to initialize. Fully restart the app and try again.';
    }
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('Connection refused')) {
      return 'Cannot reach the local YouTube proxy. Start server/ (npm start).';
    }
    return 'Could not fetch playlist videos. Check the local server and try again.';
  }

  Future<void> _syncChannelVideoCount(String channelId, int count) async {
    try {
      final channel = await _channelRepository.getChannel(channelId);
      if (channel == null || channel.videoCount == count) return;
      await _channelRepository.updateVideoCount(
        id: channelId,
        videoCount: count,
      );
      await _channelsController?.load();
    } catch (_) {
      // Count display can refresh on next load; do not fail the content op.
    }
  }
}

class ContentScope extends InheritedNotifier<ContentController> {
  const ContentScope({
    super.key,
    required ContentController controller,
    required super.child,
  }) : super(notifier: controller);

  static ContentController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ContentScope>();
    assert(scope != null, 'ContentScope not found');
    return scope!.notifier!;
  }
}
