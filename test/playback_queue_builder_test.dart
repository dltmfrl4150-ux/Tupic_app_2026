import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tupic/core/utils/playback_queue_builder.dart';
import 'package:tupic/core/utils/title_sort.dart';
import 'package:tupic/shared/models/channel_video.dart';
import 'package:tupic/shared/models/content_enums.dart';
import 'package:tupic/shared/models/content_source.dart';
import 'package:tupic/shared/models/play_order.dart';

ContentSource _source(String id) {
  final now = DateTime.utc(2024, 1, 1);
  return ContentSource(
    id: id,
    tupicChannelId: 'ch1',
    sourceType: ContentSourceType.video,
    originalUrl: 'https://youtu.be/$id',
    youtubeVideoId: id,
    displayName: id,
    createdAt: now,
    updatedAt: now,
    importStatus: ImportStatus.ready,
  );
}

ChannelVideo _video({
  required String id,
  required String title,
  required DateTime addedAt,
  required int manualOrder,
  List<String> sourceIds = const ['src'],
  bool excluded = false,
}) {
  return ChannelVideo(
    youtubeVideoId: id,
    tupicChannelId: 'ch1',
    sourceIds: sourceIds,
    title: title,
    addedAt: addedAt,
    manualOrder: manualOrder,
    metadataStatus: MetadataStatus.resolved,
    isExcluded: excluded,
  );
}

void main() {
  const builder = PlaybackQueueBuilder();
  final source = _source('src');

  test('PlayOrder.fromStorage maps legacy sequential and new values', () {
    expect(PlayOrderX.fromStorage('sequential'), PlayOrder.oldestAdded);
    expect(PlayOrderX.fromStorage('titleAsc'), PlayOrder.titleAsc);
    expect(PlayOrderX.fromStorage('titleDesc'), PlayOrder.titleDesc);
    expect(PlayOrderX.fromStorage('newestAdded'), PlayOrder.newestAdded);
    expect(PlayOrderX.fromStorage('oldestAdded'), PlayOrder.oldestAdded);
    expect(PlayOrderX.fromStorage('shuffle'), PlayOrder.shuffle);
    expect(PlayOrderX.fromStorage(null), PlayOrder.oldestAdded);
  });

  test('natural title sort handles numbers and blank titles', () {
    expect(compareNaturalTitles('Video 2', 'Video 10'), lessThan(0));
    expect(compareNaturalTitles('apple', 'Banana'), lessThan(0));
    expect(compareNaturalTitles('가', '나'), lessThan(0));
    expect(compareNaturalTitles('', 'A'), greaterThan(0));
  });

  test('titleAsc / titleDesc order by natural title', () {
    final videos = [
      _video(
        id: 'vid10xxxxx',
        title: 'Video 10',
        addedAt: DateTime.utc(2024, 1, 3),
        manualOrder: 2,
      ),
      _video(
        id: 'vid02xxxxx',
        title: 'Video 2',
        addedAt: DateTime.utc(2024, 1, 1),
        manualOrder: 0,
      ),
      _video(
        id: 'vidalpha01',
        title: 'Alpha',
        addedAt: DateTime.utc(2024, 1, 2),
        manualOrder: 1,
      ),
      _video(
        id: 'vidblank01',
        title: '   ',
        addedAt: DateTime.utc(2024, 1, 4),
        manualOrder: 3,
      ),
    ];

    final asc = builder.build(
      sources: [source],
      videos: videos,
      playOrder: PlayOrder.titleAsc,
    );
    expect(
      asc.map((v) => v.youtubeVideoId).toList(),
      ['vidalpha01', 'vid02xxxxx', 'vid10xxxxx', 'vidblank01'],
    );

    final desc = builder.build(
      sources: [source],
      videos: videos,
      playOrder: PlayOrder.titleDesc,
    );
    expect(
      desc.map((v) => v.youtubeVideoId).toList(),
      ['vid10xxxxx', 'vid02xxxxx', 'vidalpha01', 'vidblank01'],
    );
  });

  test('newestAdded / oldestAdded use channel addedAt then manualOrder', () {
    final t1 = DateTime.utc(2024, 1, 1);
    final t2 = DateTime.utc(2024, 1, 2);
    final videos = [
      _video(id: 'oldaxxxxxxx', title: 'Old', addedAt: t1, manualOrder: 0),
      _video(id: 'newbxxxxxxx', title: 'New', addedAt: t2, manualOrder: 1),
      _video(
        id: 'sameearlyxx',
        title: 'Same early',
        addedAt: t2,
        manualOrder: 2,
      ),
      _video(
        id: 'samelaterxx',
        title: 'Same later',
        addedAt: t2,
        manualOrder: 3,
      ),
    ];

    final newest = builder.build(
      sources: [source],
      videos: videos,
      playOrder: PlayOrder.newestAdded,
    );
    expect(
      newest.map((v) => v.youtubeVideoId).toList(),
      ['samelaterxx', 'sameearlyxx', 'newbxxxxxxx', 'oldaxxxxxxx'],
    );

    final oldest = builder.build(
      sources: [source],
      videos: videos,
      playOrder: PlayOrder.oldestAdded,
    );
    expect(
      oldest.map((v) => v.youtubeVideoId).toList(),
      ['oldaxxxxxxx', 'newbxxxxxxx', 'sameearlyxx', 'samelaterxx'],
    );
  });

  test('shuffle permutes with seeded random and does not mutate storage order', () {
    final videos = [
      for (var i = 0; i < 6; i++)
        _video(
          id: 'vid${i.toString().padLeft(8, 'x')}',
          title: 'T$i',
          addedAt: DateTime.utc(2024, 1, i + 1),
          manualOrder: i,
        ),
    ];
    final originalIds = videos.map((v) => v.youtubeVideoId).toList();

    final shuffled = builder.build(
      sources: [source],
      videos: videos,
      playOrder: PlayOrder.shuffle,
      random: Random(42),
    );
    expect(shuffled.length, originalIds.length);
    expect(
      shuffled.map((v) => v.youtubeVideoId).toSet(),
      originalIds.toSet(),
    );
    expect(
      shuffled.map((v) => v.youtubeVideoId).toList(),
      isNot(originalIds),
    );
    expect(videos.map((v) => v.youtubeVideoId).toList(), originalIds);

    final again = builder.build(
      sources: [source],
      videos: videos,
      playOrder: PlayOrder.shuffle,
      random: Random(7),
    );
    expect(
      again.map((v) => v.youtubeVideoId).toList(),
      isNot(shuffled.map((v) => v.youtubeVideoId).toList()),
    );
  });

  test('excludes excluded videos and preserves unique ids', () {
    final videos = [
      _video(
        id: 'keepxxxxxxx',
        title: 'Keep',
        addedAt: DateTime.utc(2024, 1, 1),
        manualOrder: 0,
      ),
      _video(
        id: 'dropxxxxxxx',
        title: 'Drop',
        addedAt: DateTime.utc(2024, 1, 2),
        manualOrder: 1,
        excluded: true,
      ),
    ];
    final queue = builder.build(
      sources: [source],
      videos: videos,
      playOrder: PlayOrder.oldestAdded,
    );
    expect(queue.map((v) => v.youtubeVideoId), ['keepxxxxxxx']);
  });

  test('buildOrderedVideos sorts without source linking', () {
    const builder = PlaybackQueueBuilder();
    final queue = builder.buildOrderedVideos(
      videos: [
        _video(
          id: 'bxxxxxxxx',
          title: 'Beta',
          addedAt: DateTime.utc(2024, 1, 2),
          manualOrder: 1,
          sourceIds: const [],
        ),
        _video(
          id: 'axxxxxxxx',
          title: 'Alpha',
          addedAt: DateTime.utc(2024, 1, 1),
          manualOrder: 0,
          sourceIds: const [],
        ),
      ],
      playOrder: PlayOrder.titleAsc,
    );
    expect(queue.map((v) => v.youtubeVideoId), ['axxxxxxxx', 'bxxxxxxxx']);
  });
}
