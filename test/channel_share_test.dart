import 'package:flutter_test/flutter_test.dart';
import 'package:tupic/features/auth/presentation/auth_controller.dart';
import 'package:tupic/features/profile/data/memory_public_profile_repository.dart';
import 'package:tupic/features/profile/presentation/public_profile_controller.dart';
import 'package:tupic/features/share/data/memory_channel_share_repository.dart';
import 'package:tupic/features/share/domain/share_snapshot_builder.dart';
import 'package:tupic/features/share/presentation/channel_share_controller.dart';
import 'package:tupic/shared/models/channel_video.dart';
import 'package:tupic/shared/models/content_enums.dart';
import 'package:tupic/shared/models/content_source.dart';
import 'package:tupic/shared/models/share_models.dart';
import 'package:tupic/shared/models/shared_channel_category.dart';
import 'package:tupic/shared/models/tupic_channel.dart';
import 'package:tupic/shared/models/video_item.dart';
import 'package:tupic/shared/repositories/channel_share_repository.dart';

TupicChannel _channel({String id = 'ch_1', String name = 'My Channel'}) {
  return TupicChannel(
    id: id,
    name: name,
    isKidsChannel: false,
    videoCount: 1,
    accentColor: const ColorSeed(0xFF6B4C9A),
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

ChannelVideo _video({
  String id = 'vid1',
  String channelId = 'ch_1',
  String title = 'Hello',
  String? customTitle,
  bool excluded = false,
  int order = 0,
}) {
  return ChannelVideo(
    youtubeVideoId: id,
    tupicChannelId: channelId,
    sourceIds: const ['src1'],
    title: title,
    originalTitle: title,
    customTitle: customTitle,
    addedAt: DateTime.utc(2026, 1, 2),
    manualOrder: order,
    metadataStatus: MetadataStatus.resolved,
    isExcluded: excluded,
  );
}

ContentSource _source({String url = 'https://youtu.be/vid1'}) {
  return ContentSource(
    id: 'src1',
    tupicChannelId: 'ch_1',
    sourceType: ContentSourceType.video,
    originalUrl: url,
    displayName: 'vid',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    importStatus: ImportStatus.ready,
    youtubeVideoId: 'vid1',
  );
}

void main() {
  group('ShareSnapshotBuilder', () {
    test('builds snapshot excluding excluded videos and keeps custom titles', () {
      final result = ShareSnapshotBuilder.build(
        channel: _channel(),
        videos: [
          _video(id: 'a', title: 'A', order: 1),
          _video(id: 'b', title: 'B', customTitle: 'Custom B', order: 0),
          _video(id: 'c', title: 'C', excluded: true, order: 2),
        ],
        sources: [_source()],
      );
      expect(result.isOk, isTrue);
      expect(result.snapshot!.videos.length, 2);
      expect(result.snapshot!.videos.first.youtubeVideoId, 'b');
      expect(result.snapshot!.videos.first.customTitle, 'Custom B');
      expect(result.snapshot!.videos.first.title, 'Custom B');
    });

    test('rejects empty, file sources, and oversized lists', () {
      expect(
        ShareSnapshotBuilder.build(
          channel: _channel(),
          videos: [_video(excluded: true)],
          sources: [_source()],
        ).errorCode,
        'no_videos',
      );
      expect(
        ShareSnapshotBuilder.build(
          channel: _channel(),
          videos: [_video()],
          sources: [_source(url: r'file:///C:/secret.mp4')],
        ).errorCode,
        'non_shareable_source',
      );
    });
  });

  group('MemoryChannelShareRepository', () {
    test('publishes v1 then v2 independently and cancels only one version', () async {
      final repo = MemoryChannelShareRepository(signedInUid: 'uid-1');
      final v1 = await repo.publish(
        SharePublishRequest(
          ownerUid: 'uid-1',
          channel: _channel(),
          videos: [_video(id: 'old', title: 'Old')],
          sources: [_source()],
          category: SharedChannelCategory.music,
        ),
      );
      expect(v1.version, 1);
      expect(v1.snapshot.videos.single.youtubeVideoId, 'old');

      final v2 = await repo.publish(
        SharePublishRequest(
          ownerUid: 'uid-1',
          channel: _channel(name: 'Updated'),
          videos: [_video(id: 'new', title: 'New')],
          sources: [_source()],
          category: SharedChannelCategory.education,
        ),
      );
      expect(v2.version, 2);
      expect(v2.snapshot.videos.single.youtubeVideoId, 'new');
      expect(v1.snapshot.videos.single.youtubeVideoId, 'old');

      final cancelled = await repo.cancelPost(ownerUid: 'uid-1', postId: v1.id);
      expect(cancelled.status, SharePostStatus.cancelled);

      final mine = await repo.listMyPosts(ownerUid: 'uid-1');
      expect(mine.length, 2);
      final still = mine.firstWhere((p) => p.id == v2.id);
      expect(still.status, SharePostStatus.published);
      expect(still.snapshot.videos.single.youtubeVideoId, 'new');
    });

    test('blocks other user publish and unsigned publish', () async {
      final repo = MemoryChannelShareRepository(signedInUid: 'uid-1');
      await expectLater(
        repo.publish(
          SharePublishRequest(
            ownerUid: 'uid-2',
            channel: _channel(),
            videos: [_video()],
            sources: [_source()],
            category: SharedChannelCategory.other,
          ),
        ),
        throwsA(isA<SharePermissionDeniedException>()),
      );
      repo.signedInUid = null;
      await expectLater(
        repo.publish(
          SharePublishRequest(
            ownerUid: 'uid-1',
            channel: _channel(),
            videos: [_video()],
            sources: [_source()],
            category: SharedChannelCategory.other,
          ),
        ),
        throwsA(isA<ShareNotSignedInException>()),
      );
    });
  });

  group('ChannelShareController', () {
    test('requires nickname before publish', () async {
      final auth = AuthController(firebaseReady: false);
      final profiles = MemoryPublicProfileRepository(signedInUid: null);
      final profile = PublicProfileController(
        authController: auth,
        repository: profiles,
      );
      final shares = MemoryChannelShareRepository(signedInUid: 'uid-1');
      final controller = ChannelShareController(
        authController: auth,
        profileController: profile,
        repository: shares,
      );
      final post = await controller.publish(
        channel: _channel(),
        videos: [_video()],
        sources: [_source()],
        category: SharedChannelCategory.games,
      );
      expect(post, isNull);
      expect(controller.errorCode, anyOf('not_signed_in', 'nickname_required'));
      controller.dispose();
      profile.dispose();
    });
  });
}
