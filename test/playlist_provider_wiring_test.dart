import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tupic/app/app.dart';
import 'package:tupic/app/locale_controller.dart';
import 'package:tupic/core/utils/playback_queue_builder.dart';
import 'package:tupic/features/channels/data/local_channel_repository.dart';
import 'package:tupic/features/content/data/http_youtube_playlist_provider.dart';
import 'package:tupic/features/content/data/local_content_repository.dart';
import 'package:tupic/features/content/data/playlist_video_fetcher.dart';
import 'package:tupic/features/content/presentation/content_controller.dart';
import 'package:tupic/features/home/data/mock_home_repository.dart';
import 'package:tupic/shared/models/content_enums.dart';
import 'package:tupic/shared/models/play_order.dart';
import 'package:tupic/shared/models/playlist_fetch_models.dart';

class _FakeFetcher implements PlaylistVideoFetcher {
  _FakeFetcher(this.result, {this.validation});

  final PlaylistFetchResult result;
  final VideoValidationResult? validation;
  int calls = 0;
  int validateCalls = 0;

  @override
  Future<PlaylistFetchResult> fetchPlaylist({
    required String playlistId,
    required int maxVideos,
    bool forceRefresh = false,
  }) async {
    calls += 1;
    return result;
  }

  @override
  Future<VideoValidationResult> validateVideoIds(
    List<String> youtubeVideoIds,
  ) async {
    validateCalls += 1;
    return validation ??
        VideoValidationResult(
          playableIds: youtubeVideoIds,
          unplayableIds: const [],
        );
  }
}

class _FailingFetcher implements PlaylistVideoFetcher {
  @override
  Future<PlaylistFetchResult> fetchPlaylist({
    required String playlistId,
    required int maxVideos,
    bool forceRefresh = false,
  }) async {
    throw const YoutubeApiException(
      code: 'connection_failed',
      message: 'server down',
    );
  }

  @override
  Future<VideoValidationResult> validateVideoIds(
    List<String> youtubeVideoIds,
  ) async {
    throw const YoutubeApiException(
      code: 'connection_failed',
      message: 'server down',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('HttpYoutubePlaylistProvider.create returns concrete instance', () {
    final provider = HttpYoutubePlaylistProvider.create();
    expect(provider, isA<HttpYoutubePlaylistProvider>());
    expect(provider, isA<PlaylistVideoFetcher>());
  });

  test('ContentController resolves playlistFetcher without null', () {
    final controller = ContentController(
      contentRepository: LocalContentRepository(),
      channelRepository: LocalChannelRepository(),
    );
    expect(controller.playlistFetcher, isA<PlaylistVideoFetcher>());
    expect(controller.playlistFetcher, same(controller.playlistFetcher));
  });

  test('ContentController uses injected fetcher for import', () async {
    final contentRepo = LocalContentRepository();
    final channelRepo = LocalChannelRepository();
    final channel = await channelRepo.createChannel(
      name: 'Wire',
      isKidsChannel: false,
    );
    final playlist = await contentRepo.addPlaylistSource(
      tupicChannelId: channel.id,
      originalUrl: 'https://www.youtube.com/playlist?list=PLabc',
      youtubePlaylistId: 'PLabc',
      displayName: 'List',
    );

    final fake = _FakeFetcher(
      const PlaylistFetchResult(
        playlistId: 'PLabc',
        videos: [
          PlaylistVideoItem(
            youtubeVideoId: 'abcdefghijk',
            title: 'From API',
            position: 0,
            thumbnailUrl: 'https://i.ytimg.com/vi/abcdefghijk/hqdefault.jpg',
          ),
        ],
        hasMore: false,
        truncatedByLimit: false,
        skippedInvalid: 0,
      ),
    );

    final controller = ContentController(
      contentRepository: contentRepo,
      channelRepository: channelRepo,
      playlistFetcher: fake,
    );

    final report = await controller.fetchPlaylistVideos(
      channelId: channel.id,
      sourceId: playlist.id,
    );

    expect(fake.calls, 1);
    expect(report.importedCount, 1);
    expect(controller.videosFor(channel.id), hasLength(1));
    expect(
      controller.sourcesFor(channel.id).first.importStatus,
      ImportStatus.fetched,
    );

    final queue = const PlaybackQueueBuilder().build(
      sources: controller.sourcesFor(channel.id),
      videos: controller.videosFor(channel.id),
      playOrder: PlayOrder.sequential,
    );
    expect(queue.map((v) => v.youtubeVideoId), ['abcdefghijk']);
  });

  test('refresh prunes unplayable existing videos via validateVideoIds', () async {
    final contentRepo = LocalContentRepository();
    final channelRepo = LocalChannelRepository();
    final channel = await channelRepo.createChannel(
      name: 'Prune',
      isKidsChannel: false,
    );
    final playlist = await contentRepo.addPlaylistSource(
      tupicChannelId: channel.id,
      originalUrl: 'https://www.youtube.com/playlist?list=PLabc',
      youtubePlaylistId: 'PLabc',
      displayName: 'List',
    );
    await contentRepo.importPlaylistVideos(
      sourceId: playlist.id,
      items: const [
        PlaylistVideoItem(
          youtubeVideoId: 'keeppublic1',
          title: 'Keep',
          position: 0,
        ),
        PlaylistVideoItem(
          youtubeVideoId: 'nowprivate1',
          title: 'Was ok',
          position: 1,
        ),
      ],
      truncatedByLimit: false,
      hasMoreOnYoutube: false,
      skippedInvalidCount: 0,
    );

    final fake = _FakeFetcher(
      const PlaylistFetchResult(
        playlistId: 'PLabc',
        videos: [
          PlaylistVideoItem(
            youtubeVideoId: 'keeppublic1',
            title: 'Keep',
            position: 0,
          ),
        ],
        hasMore: false,
        truncatedByLimit: false,
        skippedInvalid: 0,
        excludedPrivateDeleted: 1,
      ),
      validation: const VideoValidationResult(
        playableIds: [],
        unplayableIds: ['nowprivate1'],
        excludedPrivateDeleted: 1,
      ),
    );

    final controller = ContentController(
      contentRepository: contentRepo,
      channelRepository: channelRepo,
      playlistFetcher: fake,
    );
    await controller.loadChannel(channel.id);

    final report = await controller.fetchPlaylistVideos(
      channelId: channel.id,
      sourceId: playlist.id,
      forceRefresh: true,
    );

    expect(fake.validateCalls, 1);
    expect(report.prunedUnplayableCount, 1);
    expect(
      controller.videosFor(channel.id).map((v) => v.youtubeVideoId),
      ['keeppublic1'],
    );
  });

  test('connection failure marks source failed without crashing', () async {
    final contentRepo = LocalContentRepository();
    final channelRepo = LocalChannelRepository();
    final channel = await channelRepo.createChannel(
      name: 'Fail',
      isKidsChannel: false,
    );
    final playlist = await contentRepo.addPlaylistSource(
      tupicChannelId: channel.id,
      originalUrl: 'https://www.youtube.com/playlist?list=PLx',
      youtubePlaylistId: 'PLx',
      displayName: 'List',
    );

    final controller = ContentController(
      contentRepository: contentRepo,
      channelRepository: channelRepo,
      playlistFetcher: _FailingFetcher(),
    );

    await expectLater(
      () => controller.fetchPlaylistVideos(
        channelId: channel.id,
        sourceId: playlist.id,
      ),
      throwsA(
        isA<YoutubeApiException>().having(
          (e) => e.isConnectionFailed,
          'connection',
          isTrue,
        ),
      ),
    );

    expect(
      controller.sourcesFor(channel.id).first.importStatus,
      ImportStatus.failed,
    );
  });

  testWidgets('TupicApp accepts injected playlist fetcher at startup', (
    tester,
  ) async {
    final locale = LocaleController();
    await locale.load();
    final fake = _FakeFetcher(
      const PlaylistFetchResult(
        playlistId: 'PLabc',
        videos: [],
        hasMore: false,
        truncatedByLimit: false,
        skippedInvalid: 0,
      ),
    );

    await tester.pumpWidget(
      TupicApp(
        localeController: locale,
        homeRepository: MockHomeRepository(delay: Duration.zero),
        channelRepository: LocalChannelRepository(),
        contentRepository: LocalContentRepository(),
        playlistFetcher: fake,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(TupicApp), findsOneWidget);
    expect(fake, isA<PlaylistVideoFetcher>());
  });
}
