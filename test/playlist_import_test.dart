import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tupic/features/content/data/local_content_repository.dart';
import 'package:tupic/features/content/data/local_youtube_api_client.dart';
import 'package:tupic/shared/models/content_enums.dart';
import 'package:tupic/shared/models/playlist_fetch_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalYoutubeApiClient', () {
    test('parses successful playlist payload', () async {
      final client = LocalYoutubeApiClient(
        baseUrl: 'http://127.0.0.1:8787',
        httpGet: (url, {headers}) async {
          return http.Response(
            jsonEncode({
              'playlistId': 'PLabc',
              'videos': [
                {
                  'youtubeVideoId': 'abcdefghijk',
                  'title': 'One',
                  'position': 0,
                  'thumbnailUrl': 'https://i.ytimg.com/vi/abcdefghijk/hqdefault.jpg',
                },
              ],
              'hasMore': false,
              'truncatedByLimit': false,
              'skippedInvalid': 0,
              'excludedPrivateDeleted': 2,
              'excludedNotEmbeddable': 1,
              'excludedVideoIds': ['privatevid1', 'deletedvid1'],
            }),
            200,
          );
        },
      );

      final result = await client.fetchPlaylistVideos(
        playlistId: 'PLabc',
        maxVideos: 10,
      );
      expect(result.videos, hasLength(1));
      expect(result.videos.first.title, 'One');
      expect(result.excludedPrivateDeleted, 2);
      expect(result.excludedNotEmbeddable, 1);
      expect(result.excludedVideoIds, ['privatevid1', 'deletedvid1']);
    });

    test('parses validateVideos response', () async {
      final client = LocalYoutubeApiClient(
        baseUrl: 'http://127.0.0.1:8787',
        httpPost: (url, {headers, body}) async {
          expect(url.path, endsWith('/api/youtube/videos/validate'));
          return http.Response(
            jsonEncode({
              'playableIds': ['abcdefghijk'],
              'unplayableIds': ['private0001'],
              'excludedPrivateDeleted': 1,
              'excludedNotEmbeddable': 0,
              'excludedMissing': 0,
            }),
            200,
          );
        },
      );
      final result = await client.validateVideos([
        'abcdefghijk',
        'private0001',
      ]);
      expect(result.playableIds, ['abcdefghijk']);
      expect(result.unplayableIds, ['private0001']);
    });

    test('maps missing API key', () async {
      final client = LocalYoutubeApiClient(
        baseUrl: 'http://127.0.0.1:8787',
        httpGet: (url, {headers}) async {
          return http.Response(
            jsonEncode({
              'error': {
                'code': 'missing_api_key',
                'message': 'YOUTUBE_API_KEY is not set.',
              },
            }),
            503,
          );
        },
      );

      expect(
        () => client.fetchPlaylistVideos(playlistId: 'PLx', maxVideos: 5),
        throwsA(
          isA<YoutubeApiException>().having(
            (e) => e.isMissingApiKey,
            'missing key',
            isTrue,
          ),
        ),
      );
    });

    test('maps connection failure', () async {
      final client = LocalYoutubeApiClient(
        baseUrl: 'http://127.0.0.1:8787',
        httpGet: (url, {headers}) async {
          throw Exception('socket');
        },
      );
      expect(
        () => client.fetchPlaylistVideos(playlistId: 'PLx', maxVideos: 5),
        throwsA(
          isA<YoutubeApiException>().having(
            (e) => e.isConnectionFailed,
            'connection',
            isTrue,
          ),
        ),
      );
    });

    test('maps quotaExceeded', () async {
      final client = LocalYoutubeApiClient(
        baseUrl: 'http://127.0.0.1:8787',
        httpGet: (url, {headers}) async {
          return http.Response(
            jsonEncode({
              'error': {'code': 'quota_exceeded', 'message': 'quota'},
            }),
            403,
          );
        },
      );
      expect(
        () => client.fetchPlaylistVideos(playlistId: 'PLx', maxVideos: 5),
        throwsA(
          isA<YoutubeApiException>().having(
            (e) => e.isQuotaExceeded,
            'quota',
            isTrue,
          ),
        ),
      );
    });
  });

  group('importPlaylistVideos', () {
    test('imports items, dedupes, and respects free limit', () async {
      final repo = LocalContentRepository(maxVideosPerChannel: 3);
      final playlist = await repo.addPlaylistSource(
        tupicChannelId: 'ch1',
        originalUrl: 'https://www.youtube.com/playlist?list=PLabc',
        youtubePlaylistId: 'PLabc',
        displayName: 'List',
      );
      await repo.addVideoSource(
        tupicChannelId: 'ch1',
        originalUrl: 'https://youtu.be/aaaaaaaaaaa',
        youtubeVideoId: 'aaaaaaaaaaa',
        displayName: 'Existing',
      );

      final report = await repo.importPlaylistVideos(
        sourceId: playlist.id,
        items: [
          const PlaylistVideoItem(
            youtubeVideoId: 'aaaaaaaaaaa',
            title: 'Existing again',
            position: 0,
          ),
          const PlaylistVideoItem(
            youtubeVideoId: 'bbbbbbbbbbb',
            title: 'New B',
            position: 1,
            thumbnailUrl: 'https://example.com/b.jpg',
          ),
          const PlaylistVideoItem(
            youtubeVideoId: 'ccccccccccc',
            title: 'New C',
            position: 2,
          ),
          const PlaylistVideoItem(
            youtubeVideoId: 'ddddddddddd',
            title: 'Over limit',
            position: 3,
          ),
        ],
        truncatedByLimit: false,
        hasMoreOnYoutube: false,
        skippedInvalidCount: 1,
      );

      expect(report.importedCount, 2);
      expect(report.duplicateCount, 1);
      expect(report.omittedByLimitCount, 1);
      expect(report.skippedInvalidCount, 1);
      expect(report.totalLinkedToSource, 3);

      final videos = await repo.getVideos(tupicChannelId: 'ch1');
      expect(videos, hasLength(3));
      final existing = videos.firstWhere((v) => v.youtubeVideoId == 'aaaaaaaaaaa');
      expect(existing.sourceIds, contains(playlist.id));
      expect(existing.metadataStatus, MetadataStatus.resolved);

      final sources = await repo.getSources(tupicChannelId: 'ch1');
      final updated = sources.firstWhere((s) => s.id == playlist.id);
      expect(updated.importStatus, ImportStatus.partiallyFetched);
      expect(updated.fetchedVideoCount, 3);
    });

    test('empty fetch marks fetched without inventing videos', () async {
      final repo = LocalContentRepository();
      final playlist = await repo.addPlaylistSource(
        tupicChannelId: 'ch1',
        originalUrl: 'https://www.youtube.com/playlist?list=PLempty',
        youtubePlaylistId: 'PLempty',
        displayName: 'Empty',
      );
      final report = await repo.importPlaylistVideos(
        sourceId: playlist.id,
        items: const [],
        truncatedByLimit: false,
        hasMoreOnYoutube: false,
        skippedInvalidCount: 0,
      );
      expect(report.importedCount, 0);
      expect(await repo.getVideos(tupicChannelId: 'ch1'), isEmpty);
      final sources = await repo.getSources(tupicChannelId: 'ch1');
      expect(sources.first.importStatus, ImportStatus.fetched);
    });

    test('deleting playlist keeps videos linked elsewhere', () async {
      final repo = LocalContentRepository();
      final videoSource = await repo.addVideoSource(
        tupicChannelId: 'ch1',
        originalUrl: 'https://youtu.be/aaaaaaaaaaa',
        youtubeVideoId: 'aaaaaaaaaaa',
        displayName: 'A',
      );
      final playlist = await repo.addPlaylistSource(
        tupicChannelId: 'ch1',
        originalUrl: 'https://www.youtube.com/playlist?list=PLabc',
        youtubePlaylistId: 'PLabc',
        displayName: 'List',
      );
      await repo.importPlaylistVideos(
        sourceId: playlist.id,
        items: const [
          PlaylistVideoItem(
            youtubeVideoId: 'aaaaaaaaaaa',
            title: 'A',
            position: 0,
          ),
          PlaylistVideoItem(
            youtubeVideoId: 'bbbbbbbbbbb',
            title: 'B',
            position: 1,
          ),
        ],
        truncatedByLimit: false,
        hasMoreOnYoutube: false,
        skippedInvalidCount: 0,
      );

      final impact = await repo.deleteSource(playlist.id);
      expect(impact.removedVideoCount, 1); // only B
      expect(impact.retainedVideoCount, 1); // A kept via video source
      final videos = await repo.getVideos(tupicChannelId: 'ch1');
      expect(videos, hasLength(1));
      expect(videos.first.youtubeVideoId, 'aaaaaaaaaaa');
      expect(videos.first.sourceIds, [videoSource.id]);
    });

    test('pendingFetch playlist can be imported later', () async {
      final repo = LocalContentRepository();
      final playlist = await repo.addPlaylistSource(
        tupicChannelId: 'ch1',
        originalUrl: 'https://www.youtube.com/playlist?list=PLabc',
        youtubePlaylistId: 'PLabc',
        displayName: 'Old pending',
      );
      expect(playlist.importStatus, ImportStatus.pendingFetch);
      await repo.importPlaylistVideos(
        sourceId: playlist.id,
        items: const [
          PlaylistVideoItem(
            youtubeVideoId: 'abcdefghijk',
            title: 'Hello',
            position: 0,
          ),
        ],
        truncatedByLimit: false,
        hasMoreOnYoutube: false,
        skippedInvalidCount: 0,
      );
      final videos = await repo.getVideos(tupicChannelId: 'ch1');
      expect(videos.single.title, 'Hello');
      expect(videos.single.metadataStatus, MetadataStatus.resolved);
    });

    test('prunes unplayable videos but keeps shared ones', () async {
      final repo = LocalContentRepository();
      final videoSource = await repo.addVideoSource(
        tupicChannelId: 'ch1',
        originalUrl: 'https://youtu.be/shared00001',
        youtubeVideoId: 'shared00001',
        displayName: 'Shared',
      );
      final playlist = await repo.addPlaylistSource(
        tupicChannelId: 'ch1',
        originalUrl: 'https://www.youtube.com/playlist?list=PLabc',
        youtubePlaylistId: 'PLabc',
        displayName: 'List',
      );
      await repo.importPlaylistVideos(
        sourceId: playlist.id,
        items: const [
          PlaylistVideoItem(
            youtubeVideoId: 'shared00001',
            title: 'Shared',
            position: 0,
          ),
          PlaylistVideoItem(
            youtubeVideoId: 'private0001',
            title: 'Later private',
            position: 1,
          ),
          PlaylistVideoItem(
            youtubeVideoId: 'gone0000001',
            title: 'Was public',
            position: 2,
          ),
        ],
        truncatedByLimit: false,
        hasMoreOnYoutube: false,
        skippedInvalidCount: 0,
      );

      final report = await repo.importPlaylistVideos(
        sourceId: playlist.id,
        items: const [
          PlaylistVideoItem(
            youtubeVideoId: 'playable001',
            title: 'Fresh public',
            position: 0,
          ),
        ],
        truncatedByLimit: false,
        hasMoreOnYoutube: false,
        skippedInvalidCount: 0,
        excludedPrivateDeleted: 2,
        excludedNotEmbeddable: 1,
        unplayableVideoIds: {'private0001', 'gone0000001', 'shared00001'},
      );

      expect(report.prunedUnplayableCount, 3);
      expect(report.excludedPrivateDeleted, 2);
      expect(report.excludedNotEmbeddable, 1);
      expect(report.importedCount, 1);

      final videos = await repo.getVideos(tupicChannelId: 'ch1');
      expect(
        videos.map((v) => v.youtubeVideoId).toSet(),
        {'shared00001', 'playable001'},
      );
      final shared = videos.firstWhere((v) => v.youtubeVideoId == 'shared00001');
      expect(shared.sourceIds, [videoSource.id]);
      expect(
        videos.any((v) => v.youtubeVideoId == 'private0001'),
        isFalse,
      );
    });
  });
}
