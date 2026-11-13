import 'package:flutter_test/flutter_test.dart';
import 'package:tupic/features/explore/domain/shared_playback_queue.dart';
import 'package:tupic/shared/models/play_order.dart';
import 'package:tupic/shared/models/share_models.dart';
import 'package:tupic/shared/models/shared_channel_category.dart';

SharePost _post({
  required String id,
  required List<ShareSnapshotVideo> videos,
  String playOrder = 'oldestAdded',
  bool kids = false,
  SharePostStatus status = SharePostStatus.published,
  int version = 1,
}) {
  return SharePost(
    id: id,
    groupId: 'g',
    ownerUid: 'u',
    version: version,
    title: 'Title',
    category: SharedChannelCategory.music,
    isKids: kids,
    videoCount: videos.length,
    snapshot: ShareSnapshot(
      channelName: 'Snap Channel',
      isKidsChannel: kids,
      playOrder: playOrder,
      videos: videos,
    ),
    createdAt: DateTime.utc(2026, 4, 1),
    status: status,
  );
}

ShareSnapshotVideo _v(String id, String title, int order) {
  return ShareSnapshotVideo(
    youtubeVideoId: id,
    title: title,
    originalTitle: title,
    manualOrder: order,
  );
}

void main() {
  test('builds play-all queue with snapshot play order and session id', () {
    final post = _post(
      id: 'post1',
      playOrder: 'titleAsc',
      videos: [
        _v('c', 'C Song', 0),
        _v('a', 'A Song', 1),
        _v('b', 'B Song', 2),
      ],
    );

    final plan = SharedPlaybackQueue.build(post);
    expect(plan, isNotNull);
    expect(plan!.sessionChannel.id, 'shared_preview__post1');
    expect(
      SharedPlaybackQueue.isSharedSessionChannelId(plan.sessionChannel.id),
      isTrue,
    );
    expect(plan.sessionChannel.playOrder, PlayOrder.titleAsc);
    expect(plan.queue.map((v) => v.youtubeVideoId), ['a', 'b', 'c']);
    expect(plan.initialIndex, 0);
    expect(plan.version, 1);
  });

  test('starts from selected video in ordered queue', () {
    final post = _post(
      id: 'post2',
      playOrder: 'oldestAdded',
      videos: [
        _v('v1', 'One', 0),
        _v('v2', 'Two', 1),
        _v('v3', 'Three', 2),
      ],
    );

    final plan = SharedPlaybackQueue.build(
      post,
      startYoutubeVideoId: 'v2',
    );
    expect(plan, isNotNull);
    expect(plan!.initialIndex, 1);
    expect(plan.queue[plan.initialIndex].youtubeVideoId, 'v2');
  });

  test('returns null for cancelled, empty, or missing start video', () {
    expect(
      SharedPlaybackQueue.build(
        _post(
          id: 'x',
          status: SharePostStatus.cancelled,
          videos: [_v('v1', 'One', 0)],
        ),
      ),
      isNull,
    );
    expect(
      SharedPlaybackQueue.build(_post(id: 'empty', videos: const [])),
      isNull,
    );
    expect(
      SharedPlaybackQueue.build(
        _post(id: 'p', videos: [_v('v1', 'One', 0)]),
        startYoutubeVideoId: 'missing',
      ),
      isNull,
    );
  });

  test('kids flag and accent come from snapshot', () {
    final plan = SharedPlaybackQueue.build(
      _post(
        id: 'kids',
        kids: true,
        videos: [
          const ShareSnapshotVideo(
            youtubeVideoId: 'kid1',
            title: 'Kids',
            manualOrder: 0,
          ),
        ],
      ),
    );
    expect(plan!.sessionChannel.isKidsChannel, isTrue);
    expect(plan.sessionChannel.name, 'Snap Channel');
  });
}
