import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tupic/core/utils/playback_queue_builder.dart';
import 'package:tupic/features/content/data/local_content_repository.dart';
import 'package:tupic/shared/models/channel_video.dart';
import 'package:tupic/shared/models/content_enums.dart';
import 'package:tupic/shared/models/play_order.dart';
import 'package:tupic/shared/models/playlist_fetch_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('displayTitle priority and legacy migration', () {
    final now = DateTime.utc(2024, 1, 1);
    final withCustom = ChannelVideo(
      youtubeVideoId: 'abcdefghijk',
      tupicChannelId: 'ch1',
      sourceIds: const ['s1'],
      title: 'ignored',
      originalTitle: 'Original Name',
      customTitle: 'My Name',
      addedAt: now,
      manualOrder: 0,
      metadataStatus: MetadataStatus.resolved,
    );
    expect(withCustom.displayTitle, 'My Name');

    final withOriginal = withCustom.copyWith(clearCustomTitle: true);
    expect(withOriginal.displayTitle, 'Original Name');
    expect(withOriginal.hasCustomTitle, isFalse);

    final legacy = ChannelVideo.fromJson({
      'youtubeVideoId': 'abcdefghijk',
      'tupicChannelId': 'ch1',
      'sourceIds': ['s1'],
      'title': 'Playlist Real Title',
      'metadataStatus': 'resolved',
      'addedAt': now.toIso8601String(),
      'manualOrder': 0,
    });
    expect(legacy!.originalTitle, 'Playlist Real Title');
    expect(legacy.customTitle, isNull);
    expect(legacy.displayTitle, 'Playlist Real Title');

    final legacyProvisional = ChannelVideo.fromJson({
      'youtubeVideoId': 'abcdefghijk',
      'tupicChannelId': 'ch1',
      'sourceIds': ['s1'],
      'title': 'YouTube video · abcdefghijk',
      'metadataStatus': 'unresolved',
      'addedAt': now.toIso8601String(),
      'manualOrder': 0,
    });
    expect(legacyProvisional!.originalTitle, isNull);
    expect(legacyProvisional.customTitle, isNull);
    expect(legacyProvisional.displayTitle, 'YouTube video · abcdefghijk');
  });

  test('addVideoSource stores originalTitle from validation metadata', () async {
    final repo = LocalContentRepository(maxVideosPerChannel: 10);
    await repo.addVideoSource(
      tupicChannelId: 'ch1',
      originalUrl: 'https://youtu.be/abcdefghijk',
      youtubeVideoId: 'abcdefghijk',
      displayName: 'YouTube video · abcdefghijk',
      originalTitle: 'Real YouTube Title',
      thumbnailUrl: 'https://example.com/t.jpg',
    );
    final videos = await repo.getVideos(tupicChannelId: 'ch1');
    expect(videos, hasLength(1));
    expect(videos.single.originalTitle, 'Real YouTube Title');
    expect(videos.single.customTitle, isNull);
    expect(videos.single.displayTitle, 'Real YouTube Title');
    expect(videos.single.thumbnailUrl, 'https://example.com/t.jpg');
  });

  test('updateVideoCustomTitle and restore; sort uses displayTitle', () async {
    final repo = LocalContentRepository(maxVideosPerChannel: 10);
    await repo.addVideoSource(
      tupicChannelId: 'ch1',
      originalUrl: 'https://youtu.be/aaaaaaaaaaa',
      youtubeVideoId: 'aaaaaaaaaaa',
      displayName: 'A',
      originalTitle: 'Zebra Song',
    );
    await repo.addVideoSource(
      tupicChannelId: 'ch1',
      originalUrl: 'https://youtu.be/bbbbbbbbbbb',
      youtubeVideoId: 'bbbbbbbbbbb',
      displayName: 'B',
      originalTitle: 'Apple Song',
    );

    await repo.updateVideoCustomTitle(
      tupicChannelId: 'ch1',
      youtubeVideoId: 'aaaaaaaaaaa',
      customTitle: 'Banana Custom',
    );

    final videos = await repo.getVideos(tupicChannelId: 'ch1');
    final sources = await repo.getSources(tupicChannelId: 'ch1');
    final asc = const PlaybackQueueBuilder().build(
      sources: sources,
      videos: videos,
      playOrder: PlayOrder.titleAsc,
    );
    expect(
      asc.map((v) => v.displayTitle).toList(),
      ['Apple Song', 'Banana Custom'],
    );

    await repo.updateVideoCustomTitle(
      tupicChannelId: 'ch1',
      youtubeVideoId: 'aaaaaaaaaaa',
      customTitle: null,
    );
    final restored = await repo.getVideos(tupicChannelId: 'ch1');
    final a = restored.firstWhere((v) => v.youtubeVideoId == 'aaaaaaaaaaa');
    expect(a.customTitle, isNull);
    expect(a.displayTitle, 'Zebra Song');
  });

  test('playlist import fills originalTitle without wiping customTitle', () async {
    final repo = LocalContentRepository(maxVideosPerChannel: 10);
    final source = await repo.addPlaylistSource(
      tupicChannelId: 'ch1',
      originalUrl: 'https://www.youtube.com/playlist?list=PLtest',
      youtubePlaylistId: 'PLtest',
      displayName: 'PL',
    );
    await repo.addVideoSource(
      tupicChannelId: 'ch1',
      originalUrl: 'https://youtu.be/ccccccccccc',
      youtubeVideoId: 'ccccccccccc',
      displayName: 'temp',
      originalTitle: null,
      customTitle: 'User Keep',
    );
    // Link existing video into playlist source via import.
    final videos = await repo.getVideos(tupicChannelId: 'ch1');
    final linked = videos.single.copyWith(sourceIds: [source.id]);
    // Simulate pre-linked row by re-saving through import path only:
    await repo.importPlaylistVideos(
      sourceId: source.id,
      items: [
        const PlaylistVideoItem(
          youtubeVideoId: 'ccccccccccc',
          title: 'API Original',
          position: 0,
        ),
      ],
      truncatedByLimit: false,
      hasMoreOnYoutube: false,
      skippedInvalidCount: 0,
    );

    // Existing custom-only video may be a duplicate if same channel id —
    // ensure custom survives when the same id is imported.
    final after = await repo.getVideos(tupicChannelId: 'ch1');
    final video = after.firstWhere((v) => v.youtubeVideoId == 'ccccccccccc');
    expect(video.customTitle, 'User Keep');
    expect(video.displayTitle, 'User Keep');
    expect(video.originalTitle, 'API Original');
    expect(video.sourceIds, contains(source.id));
    expect(linked.customTitle, 'User Keep');
  });

  test('VideoValidationResult parses playableVideos titles', () {
    final result = VideoValidationResult.fromJson({
      'playableIds': ['abcdefghijk'],
      'playableVideos': [
        {
          'youtubeVideoId': 'abcdefghijk',
          'title': 'From Validate',
          'thumbnailUrl': 'https://img',
        },
      ],
      'unplayableIds': [],
      'ageRestrictedIds': [],
      'ageRestrictedVideos': [],
    });
    expect(result.metaFor('abcdefghijk')?.title, 'From Validate');
  });
}
