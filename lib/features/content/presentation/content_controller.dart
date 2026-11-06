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
        source = await _contentRepository.addVideoSource(
          tupicChannelId: channelId,
          originalUrl: originalUrl,
          youtubeVideoId: videoId,
          displayName: displayName,
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

      final playableIds = {
        for (final item in remote.videos) item.youtubeVideoId,
      };
      final unplayableIds = <String>{
        ...remote.excludedVideoIds,
        ...localPlaceholderIds,
      };

      // Re-validate existing linked videos not confirmed playable in this fetch.
      final needsValidation = existingLinked
          .map((v) => v.youtubeVideoId)
          .where(
            (id) => !playableIds.contains(id) && !unplayableIds.contains(id),
          )
          .toList(growable: false);
      var extraPrivate = 0;
      var extraNotEmbeddable = 0;
      var extraMissing = 0;
      if (needsValidation.isNotEmpty) {
        final validation = await playlistFetcher.validateVideoIds(
          needsValidation,
        );
        unplayableIds.addAll(validation.unplayableIds);
        extraPrivate = validation.excludedPrivateDeleted;
        extraNotEmbeddable = validation.excludedNotEmbeddable;
        extraMissing = validation.excludedMissing;
      }

      final report = await _contentRepository.importPlaylistVideos(
        sourceId: sourceId,
        items: remote.videos,
        truncatedByLimit: remote.truncatedByLimit || remaining < max,
        hasMoreOnYoutube: remote.hasMore,
        skippedInvalidCount: remote.skippedInvalid,
        excludedPrivateDeleted:
            remote.excludedPrivateDeleted + extraPrivate,
        excludedNotEmbeddable:
            remote.excludedNotEmbeddable + extraNotEmbeddable,
        excludedMissing: remote.excludedMissing + extraMissing,
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
