import '../models/channel_video.dart';
import '../models/content_enums.dart';
import '../models/content_source.dart';
import '../models/playlist_fetch_models.dart';

abstract class ContentRepository {
  Future<List<ContentSource>> getSources({String? tupicChannelId});

  Future<List<ChannelVideo>> getVideos({String? tupicChannelId});

  Future<int> countActiveVideos(String tupicChannelId);

  Future<ContentSource> addVideoSource({
    required String tupicChannelId,
    required String originalUrl,
    required String youtubeVideoId,
    required String displayName,
  });

  Future<ContentSource> addPlaylistSource({
    required String tupicChannelId,
    required String originalUrl,
    required String youtubePlaylistId,
    required String displayName,
  });

  Future<ContentSource> addCreatorSource({
    required String tupicChannelId,
    required String originalUrl,
    required String displayName,
    String? youtubeChannelId,
    String? youtubeHandle,
    String? youtubeUsername,
    String? youtubeCustomName,
    CreatorImportMode importMode = CreatorImportMode.recent30,
    CreatorSortOrder sortOrder = CreatorSortOrder.newest,
    bool autoSyncEnabled = false,
  });

  Future<ContentSource> updateCreatorOptions({
    required String sourceId,
    CreatorImportMode? importMode,
    CreatorSortOrder? sortOrder,
    bool? autoSyncEnabled,
  });

  Future<void> reorderVideos({
    required String tupicChannelId,
    required List<String> youtubeVideoIdsInOrder,
  });

  Future<ChannelVideo> setVideoExcluded({
    required String tupicChannelId,
    required String youtubeVideoId,
    required bool excluded,
  });

  Future<void> deleteVideo({
    required String tupicChannelId,
    required String youtubeVideoId,
  });

  /// Returns orphaned video count that would be removed with the source.
  Future<SourceDeleteImpact> deleteSource(String sourceId);

  Future<void> deleteAllForChannel(String tupicChannelId);

  /// Merges fetched playlist items into local videos linked to [sourceId].
  ///
  /// [unplayableVideoIds] are unlinked from this source (and deleted when
  /// orphaned). Videos still referenced by other sources are retained.
  Future<PlaylistImportReport> importPlaylistVideos({
    required String sourceId,
    required List<PlaylistVideoItem> items,
    required bool truncatedByLimit,
    required bool hasMoreOnYoutube,
    required int skippedInvalidCount,
    int excludedPrivateDeleted = 0,
    int excludedNotEmbeddable = 0,
    int excludedMissing = 0,
    Set<String> unplayableVideoIds = const {},
  });

  Future<ContentSource> updateSourceImportState({
    required String sourceId,
    required ImportStatus importStatus,
    DateTime? lastFetchedAt,
    int? fetchedVideoCount,
    String? lastErrorMessage,
    bool clearLastError = false,
  });
}

class SourceDeleteImpact {
  const SourceDeleteImpact({
    required this.source,
    required this.removedVideoCount,
    required this.retainedVideoCount,
  });

  final ContentSource source;
  final int removedVideoCount;
  final int retainedVideoCount;
}

class DuplicateVideoException implements Exception {
  const DuplicateVideoException(this.youtubeVideoId);

  final String youtubeVideoId;

  @override
  String toString() => 'DuplicateVideoException($youtubeVideoId)';
}

class VideoLimitExceededException implements Exception {
  const VideoLimitExceededException(this.maxVideos);

  final int maxVideos;

  @override
  String toString() => 'VideoLimitExceededException($maxVideos)';
}

class ContentSourceNotFoundException implements Exception {
  const ContentSourceNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'ContentSourceNotFoundException($id)';
}

class AutoSyncNotAllowedException implements Exception {
  const AutoSyncNotAllowedException();

  @override
  String toString() => 'AutoSyncNotAllowedException';
}

/// Future YouTube metadata/playlist/creator providers (no network in STEP 3A).
abstract class YoutubeMetadataProvider {
  Future<YoutubeProviderStatus> fetchVideoMetadata(String videoId);
}

abstract class YoutubePlaylistProvider {
  Future<YoutubeProviderStatus> fetchPlaylistItems(String playlistId);
}

abstract class YoutubeCreatorProvider {
  Future<YoutubeProviderStatus> fetchCreatorVideos({
    required String? channelId,
    required String? handle,
  });
}

enum YoutubeProviderConnectionState { notConnected, unavailable, ready }

class YoutubeProviderStatus {
  const YoutubeProviderStatus({
    required this.state,
    this.message = 'YouTube API is not connected yet.',
  });

  final YoutubeProviderConnectionState state;
  final String message;

  static const notConnected = YoutubeProviderStatus(
    state: YoutubeProviderConnectionState.notConnected,
  );
}
