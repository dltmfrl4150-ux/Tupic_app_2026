import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tupic/features/channels/data/local_channel_repository.dart';
import 'package:tupic/features/content/data/local_content_repository.dart';
import 'package:tupic/features/content/data/playlist_video_fetcher.dart';
import 'package:tupic/features/content/presentation/content_controller.dart';
import 'package:tupic/shared/models/content_enums.dart';
import 'package:tupic/shared/models/playlist_fetch_models.dart';

class _CreatorFetcher implements PlaylistVideoFetcher {
  @override
  Future<PlaylistFetchResult> fetchPlaylist({
    required String playlistId,
    required int maxVideos,
    bool forceRefresh = false,
  }) async {
    return PlaylistFetchResult(
      playlistId: playlistId,
      videos: [
        for (var i = 0; i < 3; i++)
          PlaylistVideoItem(
            youtubeVideoId: 'vid${i.toString().padLeft(8, 'x')}',
            title: 'Title $i',
            position: i,
            publishedAt: DateTime.utc(2024, 1, i + 1),
          ),
      ],
      hasMore: false,
      truncatedByLimit: false,
      skippedInvalid: 0,
    );
  }

  @override
  Future<VideoValidationResult> validateVideoIds(
    List<String> youtubeVideoIds,
  ) async {
    return VideoValidationResult(
      playableIds: youtubeVideoIds,
      unplayableIds: const [],
      playableVideos: [
        for (final id in youtubeVideoIds)
          PlaylistVideoItem(
            youtubeVideoId: id,
            title: 'Real $id',
            position: 0,
            channelTitle: 'Creator',
          ),
      ],
    );
  }

  @override
  Future<ResolvedYoutubeChannel> resolveChannel({
    String? channelId,
    String? handle,
    String? username,
    String? customName,
  }) async {
    return const ResolvedYoutubeChannel(
      channelId: 'UCabcdefghijklmnopqrsuvw',
      title: 'Creator Name',
      uploadsPlaylistId: 'UUabcdefghijklmnopqrsuvw',
      thumbnailUrl: 'https://example.com/c.jpg',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('preview and selective creator import stores original titles', () async {
    final contentRepo = LocalContentRepository(maxVideosPerChannel: 10);
    final channelRepo = LocalChannelRepository();
    final channel = await channelRepo.createChannel(
      name: 'Ch',
      isKidsChannel: false,
    );
    final controller = ContentController(
      contentRepository: contentRepo,
      channelRepository: channelRepo,
      playlistFetcher: _CreatorFetcher(),
    );

    final resolved = await controller.resolveCreatorChannel(handle: 'demo');
    expect(resolved.title, 'Creator Name');

    final preview = await controller.previewPlaylist(
      channelId: channel.id,
      playlistId: resolved.uploadsPlaylistId,
      maxVideos: 30,
    );
    expect(preview.videos, hasLength(3));

    final report = await controller.importSelectedVideos(
      channelId: channel.id,
      sourceType: ContentSourceType.creator,
      originalUrl: 'https://youtube.com/@demo',
      displayName: resolved.title,
      selected: preview.videos.take(2).toList(),
      youtubePlaylistId: resolved.uploadsPlaylistId,
      youtubeChannelId: resolved.channelId,
      youtubeHandle: 'demo',
    );
    expect(report.importedCount, 2);

    final videos = await contentRepo.getVideos(tupicChannelId: channel.id);
    expect(videos, hasLength(2));
    expect(videos.every((v) => v.originalTitle != null), isTrue);

    final sources = await contentRepo.getSources(tupicChannelId: channel.id);
    expect(sources.single.sourceType, ContentSourceType.creator);
    expect(sources.single.youtubePlaylistId, resolved.uploadsPlaylistId);
  });

  test('previewSingleVideo returns title from validation meta', () async {
    final contentRepo = LocalContentRepository();
    final channelRepo = LocalChannelRepository();
    final channel = await channelRepo.createChannel(
      name: 'Ch',
      isKidsChannel: false,
    );
    final controller = ContentController(
      contentRepository: contentRepo,
      channelRepository: channelRepo,
      playlistFetcher: _CreatorFetcher(),
    );
    final meta = await controller.previewSingleVideo(
      channelId: channel.id,
      youtubeVideoId: 'abcdefghijk',
    );
    expect(meta.title, 'Real abcdefghijk');
    expect(meta.channelTitle, 'Creator');
  });
}
