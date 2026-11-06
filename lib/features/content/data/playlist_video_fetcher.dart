import '../../../shared/models/playlist_fetch_models.dart';

/// Fetches playlist videos for STEP 4A (local proxy or test doubles).
abstract class PlaylistVideoFetcher {
  Future<PlaylistFetchResult> fetchPlaylist({
    required String playlistId,
    required int maxVideos,
    bool forceRefresh = false,
  });

  /// Re-validates existing local video IDs via the proxy `videos.list` path.
  Future<VideoValidationResult> validateVideoIds(List<String> youtubeVideoIds);
}
