import '../../../shared/repositories/content_repository.dart';

/// Explicit no-op providers — never invent video lists.
class StubYoutubeMetadataProvider implements YoutubeMetadataProvider {
  const StubYoutubeMetadataProvider();

  @override
  Future<YoutubeProviderStatus> fetchVideoMetadata(String videoId) async {
    return YoutubeProviderStatus.notConnected;
  }
}

class StubYoutubePlaylistProvider implements YoutubePlaylistProvider {
  const StubYoutubePlaylistProvider();

  @override
  Future<YoutubeProviderStatus> fetchPlaylistItems(String playlistId) async {
    return YoutubeProviderStatus.notConnected;
  }
}

class StubYoutubeCreatorProvider implements YoutubeCreatorProvider {
  const StubYoutubeCreatorProvider();

  @override
  Future<YoutubeProviderStatus> fetchCreatorVideos({
    required String? channelId,
    required String? handle,
  }) async {
    return YoutubeProviderStatus.notConnected;
  }
}
