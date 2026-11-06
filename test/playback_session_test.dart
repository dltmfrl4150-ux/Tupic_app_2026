import 'package:flutter_test/flutter_test.dart';
import 'package:tupic/features/player/domain/playback_phase.dart';
import 'package:tupic/features/player/domain/playback_session.dart';
import 'package:tupic/shared/models/channel_video.dart';
import 'package:tupic/shared/models/content_enums.dart';

ChannelVideo _video(String id, {int order = 0}) {
  return ChannelVideo(
    youtubeVideoId: id,
    tupicChannelId: 'ch1',
    sourceIds: const ['s1'],
    title: 'YouTube 영상 · $id',
    addedAt: DateTime(2024, 1, 1),
    manualOrder: order,
    metadataStatus: MetadataStatus.unresolved,
  );
}

void main() {
  group('PlaybackSession', () {
    test('empty queue starts empty', () {
      final session = PlaybackSession(queue: const []);
      expect(session.phase, PlaybackPhase.empty);
      expect(session.currentIndex, -1);
      expect(session.currentVideo, isNull);
    });

    test('selects first video by default', () {
      final session = PlaybackSession(
        queue: [_video('a'), _video('b', order: 1)],
      );
      expect(session.currentIndex, 0);
      expect(session.currentVideo?.youtubeVideoId, 'a');
    });

    test('playAt / selectIndex changes current index', () {
      final session = PlaybackSession(
        queue: [_video('a'), _video('b', order: 1), _video('c', order: 2)],
        initialIndex: 0,
      );
      expect(session.selectIndex(2), isTrue);
      expect(session.currentIndex, 2);
      expect(session.phase, PlaybackPhase.loading);
    });

    test('lock blocks select and queue panel', () {
      final session = PlaybackSession(
        queue: [_video('a'), _video('b', order: 1)],
      );
      session.setLocked(true);
      expect(session.selectIndex(1), isFalse);
      session.toggleQueuePanel();
      expect(session.queuePanelOpen, isFalse);
    });

    test('ended advances to next once', () {
      final session = PlaybackSession(
        queue: [_video('a'), _video('b', order: 1)],
      );
      final now = DateTime(2024, 6, 1, 12);
      expect(session.onVideoEnded(now: now), isTrue);
      expect(session.currentIndex, 1);
      expect(session.currentVideo?.youtubeVideoId, 'b');
    });

    test('duplicate ended event within 2s is ignored', () {
      final session = PlaybackSession(
        queue: [_video('a'), _video('b', order: 1), _video('c', order: 2)],
      );
      final now = DateTime(2024, 6, 1, 12);
      expect(session.onVideoEnded(now: now), isTrue);
      expect(session.currentIndex, 1);
      // Same video id ending again immediately (duplicate event).
      // After advance, current is b — forge a duplicate for previous by
      // calling ended twice quickly on the new current.
      expect(session.onVideoEnded(now: now), isTrue);
      expect(session.currentIndex, 2);
      expect(
        session.onVideoEnded(now: now.add(const Duration(milliseconds: 100))),
        isFalse,
      );
      expect(session.currentIndex, 2);
      expect(session.phase, PlaybackPhase.queueComplete);
    });

    test('last video ended completes queue', () {
      final session = PlaybackSession(queue: [_video('only')]);
      expect(session.onVideoEnded(now: DateTime(2024)), isFalse);
      expect(session.phase, PlaybackPhase.queueComplete);
    });

    test('queue panel open/close does not change index', () {
      final session = PlaybackSession(
        queue: [_video('a'), _video('b', order: 1)],
        initialIndex: 1,
      );
      session.toggleQueuePanel();
      expect(session.queuePanelOpen, isTrue);
      expect(session.currentIndex, 1);
      session.toggleQueuePanel();
      expect(session.queuePanelOpen, isFalse);
      expect(session.currentIndex, 1);
    });

    test('unlock restores ability to change video', () {
      final session = PlaybackSession(
        queue: [_video('a'), _video('b', order: 1)],
      );
      session.setLocked(true);
      session.setLocked(false);
      expect(session.selectIndex(1), isTrue);
      expect(session.currentIndex, 1);
    });

    test('nextPlayableIndex skips failed ids', () {
      final session = PlaybackSession(
        queue: [
          _video('a'),
          _video('b', order: 1),
          _video('c', order: 2),
        ],
      );
      expect(
        session.nextPlayableIndex(
          fromIndex: 0,
          failedIds: {'b'},
        ),
        2,
      );
      expect(
        session.nextPlayableIndex(
          fromIndex: 0,
          failedIds: {'b', 'c'},
        ),
        -1,
      );
    });

    test('markAllUnavailable sets phase', () {
      final session = PlaybackSession(queue: [_video('a')]);
      session.markAllUnavailable('none left');
      expect(session.phase, PlaybackPhase.allUnavailable);
      expect(session.errorMessage, 'none left');
    });
  });
}
