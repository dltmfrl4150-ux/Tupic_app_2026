import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tupic/features/channels/data/local_channel_repository.dart';
import 'package:tupic/features/content/data/local_content_repository.dart';
import 'package:tupic/features/content/data/playlist_video_fetcher.dart';
import 'package:tupic/features/content/presentation/content_controller.dart';
import 'package:tupic/shared/models/playlist_fetch_models.dart';
import 'package:tupic/shared/models/youtube_url_parse_result.dart';

class _FakeFetcher implements PlaylistVideoFetcher {
  _FakeFetcher({
    required this.validation,
    this.playlistResult,
  });

  final VideoValidationResult validation;
  final PlaylistFetchResult? playlistResult;
  int validateCalls = 0;

  @override
  Future<PlaylistFetchResult> fetchPlaylist({
    required String playlistId,
    required int maxVideos,
    bool forceRefresh = false,
  }) async {
    return playlistResult ??
        PlaylistFetchResult(
          playlistId: playlistId,
          videos: const [],
          hasMore: false,
          truncatedByLimit: false,
          skippedInvalid: 0,
        );
  }

  @override
  Future<VideoValidationResult> validateVideoIds(
    List<String> youtubeVideoIds,
  ) async {
    validateCalls += 1;
    return validation;
  }

  @override
  Future<ResolvedYoutubeChannel> resolveChannel({
    String? channelId,
    String? handle,
    String? username,
    String? customName,
  }) async {
    return ResolvedYoutubeChannel(
      channelId: channelId ?? 'UCxxxxxxxxxxxxxxxxxxxxxx',
      title: 'Fake Channel',
      uploadsPlaylistId: 'UUxxxxxxxxxxxxxxxxxxxxxx',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<(LocalContentRepository, LocalChannelRepository, String)> channel({
    required bool kids,
  }) async {
    final contentRepo = LocalContentRepository();
    final channelRepo = LocalChannelRepository();
    final created = await channelRepo.createChannel(
      name: kids ? 'Kids' : 'General',
      isKidsChannel: kids,
    );
    return (contentRepo, channelRepo, created.id);
  }

  test('kids + general video registers', () async {
    final (contentRepo, channelRepo, channelId) = await channel(kids: true);
    final fetcher = _FakeFetcher(
      validation: const VideoValidationResult(
        playableIds: ['abcdefghijk'],
        unplayableIds: [],
      ),
    );
    final controller = ContentController(
      contentRepository: contentRepo,
      channelRepository: channelRepo,
      playlistFetcher: fetcher,
    );

    await controller.addParsedContent(
      channelId: channelId,
      parsed: const YoutubeParsedVideo(
        videoId: 'abcdefghijk',
        originalUrl: 'https://youtu.be/abcdefghijk',
      ),
      displayName: 'OK',
    );

    expect(await contentRepo.getVideos(tupicChannelId: channelId), hasLength(1));
    controller.dispose();
  });

  test('kids + age-restricted video rejected', () async {
    final (contentRepo, channelRepo, channelId) = await channel(kids: true);
    final fetcher = _FakeFetcher(
      validation: const VideoValidationResult(
        playableIds: [],
        unplayableIds: ['abcdefghijk'],
        ageRestrictedIds: ['abcdefghijk'],
        excludedAgeRestricted: 1,
      ),
    );
    final controller = ContentController(
      contentRepository: contentRepo,
      channelRepository: channelRepo,
      playlistFetcher: fetcher,
    );

    await expectLater(
      () => controller.addParsedContent(
        channelId: channelId,
        parsed: const YoutubeParsedVideo(
          videoId: 'abcdefghijk',
          originalUrl: 'https://youtu.be/abcdefghijk',
        ),
        displayName: 'Restricted',
      ),
      throwsA(isA<AgeRestrictedVideoException>()),
    );
    expect(await contentRepo.getVideos(tupicChannelId: channelId), isEmpty);
    controller.dispose();
  });

  test('general + general video registers', () async {
    final (contentRepo, channelRepo, channelId) = await channel(kids: false);
    final fetcher = _FakeFetcher(
      validation: const VideoValidationResult(
        playableIds: ['abcdefghijk'],
        unplayableIds: [],
      ),
    );
    final controller = ContentController(
      contentRepository: contentRepo,
      channelRepository: channelRepo,
      playlistFetcher: fetcher,
    );

    await controller.addParsedContent(
      channelId: channelId,
      parsed: const YoutubeParsedVideo(
        videoId: 'abcdefghijk',
        originalUrl: 'https://youtu.be/abcdefghijk',
      ),
      displayName: 'OK',
    );
    expect(await contentRepo.getVideos(tupicChannelId: channelId), hasLength(1));
    controller.dispose();
  });

  test('general + age-restricted video allowed', () async {
    final (contentRepo, channelRepo, channelId) = await channel(kids: false);
    final fetcher = _FakeFetcher(
      validation: const VideoValidationResult(
        playableIds: [],
        unplayableIds: ['abcdefghijk'],
        ageRestrictedIds: ['abcdefghijk'],
        excludedAgeRestricted: 1,
      ),
    );
    final controller = ContentController(
      contentRepository: contentRepo,
      channelRepository: channelRepo,
      playlistFetcher: fetcher,
    );

    await controller.addParsedContent(
      channelId: channelId,
      parsed: const YoutubeParsedVideo(
        videoId: 'abcdefghijk',
        originalUrl: 'https://youtu.be/abcdefghijk',
      ),
      displayName: 'Restricted OK on general',
    );

    final videos = await contentRepo.getVideos(tupicChannelId: channelId);
    expect(videos, hasLength(1));
    expect(videos.single.youtubeVideoId, 'abcdefghijk');
    controller.dispose();
  });

  test('verification failure blocks both kids and general', () async {
    for (final kids in [true, false]) {
      SharedPreferences.setMockInitialValues({});
      final (contentRepo, channelRepo, channelId) = await channel(kids: kids);
      final fetcher = _FakeFetcher(
        validation: const VideoValidationResult(
          playableIds: [],
          unplayableIds: ['abcdefghijk'],
          verificationFailedIds: ['abcdefghijk'],
          excludedVerificationFailed: 1,
        ),
      );
      final controller = ContentController(
        contentRepository: contentRepo,
        channelRepository: channelRepo,
        playlistFetcher: fetcher,
      );

      await expectLater(
        () => controller.addParsedContent(
          channelId: channelId,
          parsed: const YoutubeParsedVideo(
            videoId: 'abcdefghijk',
            originalUrl: 'https://youtu.be/abcdefghijk',
          ),
          displayName: 'Unknown',
        ),
        throwsA(isA<VideoVerificationFailedException>()),
      );
      expect(await contentRepo.getVideos(tupicChannelId: channelId), isEmpty);
      controller.dispose();
    }
  });

  test('kids playlist excludes age-restricted only', () async {
    final (contentRepo, channelRepo, channelId) = await channel(kids: true);
    final playlist = await contentRepo.addPlaylistSource(
      tupicChannelId: channelId,
      originalUrl: 'https://www.youtube.com/playlist?list=PLmix',
      youtubePlaylistId: 'PLmix',
      displayName: 'Mix',
    );

    final fetcher = _FakeFetcher(
      validation: const VideoValidationResult(
        playableIds: [],
        unplayableIds: [],
      ),
      playlistResult: PlaylistFetchResult(
        playlistId: 'PLmix',
        videos: const [
          PlaylistVideoItem(
            youtubeVideoId: 'allowed00001',
            title: 'Allowed',
            position: 0,
          ),
        ],
        hasMore: false,
        truncatedByLimit: false,
        skippedInvalid: 0,
        excludedAgeRestricted: 2,
        ageRestrictedIds: const ['age00000001', 'age00000002'],
        ageRestrictedVideos: const [
          PlaylistVideoItem(
            youtubeVideoId: 'age00000001',
            title: 'Age 1',
            position: 1,
          ),
          PlaylistVideoItem(
            youtubeVideoId: 'age00000002',
            title: 'Age 2',
            position: 2,
          ),
        ],
        excludedVideoIds: const ['age00000001', 'age00000002'],
      ),
    );

    final controller = ContentController(
      contentRepository: contentRepo,
      channelRepository: channelRepo,
      playlistFetcher: fetcher,
    );

    final report = await controller.fetchPlaylistVideos(
      channelId: channelId,
      sourceId: playlist.id,
    );

    expect(report.importedCount, 1);
    expect(report.excludedAgeRestricted, 2);
    final videos = await contentRepo.getVideos(tupicChannelId: channelId);
    expect(videos.map((v) => v.youtubeVideoId), ['allowed00001']);
    controller.dispose();
  });

  test('general playlist includes age-restricted', () async {
    final (contentRepo, channelRepo, channelId) = await channel(kids: false);
    final playlist = await contentRepo.addPlaylistSource(
      tupicChannelId: channelId,
      originalUrl: 'https://www.youtube.com/playlist?list=PLmix',
      youtubePlaylistId: 'PLmix',
      displayName: 'Mix',
    );

    final fetcher = _FakeFetcher(
      validation: const VideoValidationResult(
        playableIds: [],
        unplayableIds: [],
      ),
      playlistResult: PlaylistFetchResult(
        playlistId: 'PLmix',
        videos: const [
          PlaylistVideoItem(
            youtubeVideoId: 'allowed00001',
            title: 'Allowed',
            position: 0,
          ),
        ],
        hasMore: false,
        truncatedByLimit: false,
        skippedInvalid: 0,
        excludedAgeRestricted: 1,
        ageRestrictedIds: const ['age00000001'],
        ageRestrictedVideos: const [
          PlaylistVideoItem(
            youtubeVideoId: 'age00000001',
            title: 'Age 1',
            position: 1,
          ),
        ],
        excludedVideoIds: const ['age00000001'],
      ),
    );

    final controller = ContentController(
      contentRepository: contentRepo,
      channelRepository: channelRepo,
      playlistFetcher: fetcher,
    );

    final report = await controller.fetchPlaylistVideos(
      channelId: channelId,
      sourceId: playlist.id,
    );

    expect(report.importedCount, 2);
    expect(report.excludedAgeRestricted, 0);
    final videos = await contentRepo.getVideos(tupicChannelId: channelId);
    expect(
      videos.map((v) => v.youtubeVideoId).toSet(),
      {'allowed00001', 'age00000001'},
    );
    controller.dispose();
  });
}
