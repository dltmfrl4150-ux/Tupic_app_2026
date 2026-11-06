import '../../../shared/models/playlist_fetch_models.dart';
import '../../../shared/repositories/content_repository.dart';
import 'local_youtube_api_client.dart';
import 'playlist_video_fetcher.dart';
import 'stub_youtube_providers.dart';

/// Playlist provider backed by the local Node proxy (STEP 4A).
class HttpYoutubePlaylistProvider
    implements YoutubePlaylistProvider, PlaylistVideoFetcher {
  HttpYoutubePlaylistProvider({LocalYoutubeApiClient? client})
    : _client = client ?? LocalYoutubeApiClient();

  final LocalYoutubeApiClient _client;

  /// Factory used by app wiring so creation is never an implicit null path.
  factory HttpYoutubePlaylistProvider.create() {
    return HttpYoutubePlaylistProvider(client: LocalYoutubeApiClient());
  }

  @override
  Future<YoutubeProviderStatus> fetchPlaylistItems(String playlistId) async {
    try {
      await fetchPlaylist(playlistId: playlistId, maxVideos: 1);
      return const YoutubeProviderStatus(
        state: YoutubeProviderConnectionState.ready,
        message: 'Connected via local proxy',
      );
    } on YoutubeApiException catch (e) {
      return YoutubeProviderStatus(
        state: YoutubeProviderConnectionState.unavailable,
        message: e.message,
      );
    }
  }

  @override
  Future<PlaylistFetchResult> fetchPlaylist({
    required String playlistId,
    required int maxVideos,
    bool forceRefresh = false,
  }) {
    return _client.fetchPlaylistVideos(
      playlistId: playlistId,
      maxVideos: maxVideos,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<VideoValidationResult> validateVideoIds(List<String> youtubeVideoIds) {
    return _client.validateVideos(youtubeVideoIds);
  }
}

/// Keeps stub available when proxy is disabled (release / tests without network).
class FallbackYoutubePlaylistProvider implements YoutubePlaylistProvider {
  const FallbackYoutubePlaylistProvider();

  @override
  Future<YoutubeProviderStatus> fetchPlaylistItems(String playlistId) async {
    return const StubYoutubePlaylistProvider().fetchPlaylistItems(playlistId);
  }
}
