import 'package:flutter_test/flutter_test.dart';
import 'package:tupic/features/player/domain/playback_resume.dart';
import 'package:tupic/shared/models/channel_playback_progress.dart';
import 'package:tupic/shared/models/channel_video.dart';
import 'package:tupic/shared/models/content_enums.dart';
import 'package:tupic/shared/models/play_order.dart';

ChannelVideo _v(String id, {int order = 0}) {
  return ChannelVideo(
    youtubeVideoId: id,
    tupicChannelId: 'ch',
    sourceIds: const ['s'],
    title: id,
    addedAt: DateTime(2024),
    manualOrder: order,
    metadataStatus: MetadataStatus.unresolved,
  );
}

void main() {
  group('PlaybackResume.resolve', () {
    test('empty queue', () {
      final plan = PlaybackResume.resolve(
        builtQueue: const [],
        playOrder: PlayOrder.sequential,
      );
      expect(plan.queue, isEmpty);
      expect(plan.index, -1);
    });

    test('starts at first video without progress', () {
      final plan = PlaybackResume.resolve(
        builtQueue: [_v('a'), _v('b', order: 1)],
        playOrder: PlayOrder.sequential,
      );
      expect(plan.index, 0);
      expect(plan.startSeconds, 0);
      expect(plan.resumed, isFalse);
    });

    test('restores saved video and position', () {
      final plan = PlaybackResume.resolve(
        builtQueue: [_v('a'), _v('b', order: 1), _v('c', order: 2)],
        playOrder: PlayOrder.sequential,
        progress: ChannelPlaybackProgress(
          tupicChannelId: 'ch',
          youtubeVideoId: 'b',
          positionSeconds: 42.5,
          updatedAt: DateTime(2024, 2),
        ),
      );
      expect(plan.index, 1);
      expect(plan.startSeconds, 42.5);
      expect(plan.resumed, isTrue);
    });

    test('invalid negative position becomes 0', () {
      final plan = PlaybackResume.resolve(
        builtQueue: [_v('a')],
        playOrder: PlayOrder.sequential,
        progress: ChannelPlaybackProgress(
          tupicChannelId: 'ch',
          youtubeVideoId: 'a',
          positionSeconds: -3,
          updatedAt: DateTime(2024),
        ),
      );
      expect(plan.startSeconds, 0);
    });

    test('missing video falls back to first', () {
      final plan = PlaybackResume.resolve(
        builtQueue: [_v('a'), _v('b', order: 1)],
        playOrder: PlayOrder.sequential,
        progress: ChannelPlaybackProgress(
          tupicChannelId: 'ch',
          youtubeVideoId: 'gone',
          positionSeconds: 10,
          updatedAt: DateTime(2024),
        ),
      );
      expect(plan.index, 0);
      expect(plan.startSeconds, 0);
      expect(plan.resumed, isFalse);
    });

    test('pruned last-watched advances to next session id', () {
      final plan = PlaybackResume.resolve(
        builtQueue: [_v('a'), _v('c', order: 2)],
        playOrder: PlayOrder.sequential,
        progress: ChannelPlaybackProgress(
          tupicChannelId: 'ch',
          youtubeVideoId: 'b',
          positionSeconds: 15,
          updatedAt: DateTime(2024),
          sessionQueueIds: const ['a', 'b', 'c'],
        ),
      );
      expect(plan.index, 1);
      expect(plan.queue[plan.index].youtubeVideoId, 'c');
      expect(plan.startSeconds, 0);
      expect(plan.resumed, isTrue);
    });

    test('near end with known duration advances to next', () {
      final plan = PlaybackResume.resolve(
        builtQueue: [_v('a'), _v('b', order: 1)],
        playOrder: PlayOrder.sequential,
        knownDurationSeconds: 100,
        progress: ChannelPlaybackProgress(
          tupicChannelId: 'ch',
          youtubeVideoId: 'a',
          positionSeconds: 97,
          updatedAt: DateTime(2024),
        ),
      );
      expect(plan.index, 1);
      expect(plan.startSeconds, 0);
    });

    test('force video id overrides resume', () {
      final plan = PlaybackResume.resolve(
        builtQueue: [_v('a'), _v('b', order: 1)],
        playOrder: PlayOrder.sequential,
        forceYoutubeVideoId: 'b',
        progress: ChannelPlaybackProgress(
          tupicChannelId: 'ch',
          youtubeVideoId: 'a',
          positionSeconds: 30,
          updatedAt: DateTime(2024),
        ),
      );
      expect(plan.index, 1);
      expect(plan.startSeconds, 0);
      expect(plan.resumed, isFalse);
    });

    test('restores shuffle session order when compatible', () {
      final plan = PlaybackResume.resolve(
        builtQueue: [_v('a'), _v('b', order: 1), _v('c', order: 2)],
        playOrder: PlayOrder.shuffle,
        progress: ChannelPlaybackProgress(
          tupicChannelId: 'ch',
          youtubeVideoId: 'c',
          positionSeconds: 12,
          updatedAt: DateTime(2024),
          sessionQueueIds: const ['c', 'a', 'b'],
          sessionPlayOrder: PlayOrder.shuffle,
        ),
      );
      expect(plan.queue.map((v) => v.youtubeVideoId).toList(), [
        'c',
        'a',
        'b',
      ]);
      expect(plan.index, 0);
      expect(plan.startSeconds, 12);
    });

    test('channel progress records are independent keys', () {
      final a = ChannelPlaybackProgress(
        tupicChannelId: 'ch1',
        youtubeVideoId: 'a',
        positionSeconds: 1,
        updatedAt: DateTime(2024),
      );
      final b = ChannelPlaybackProgress(
        tupicChannelId: 'ch2',
        youtubeVideoId: 'b',
        positionSeconds: 2,
        updatedAt: DateTime(2024),
      );
      expect(a.tupicChannelId, isNot(b.tupicChannelId));
    });
  });
}
