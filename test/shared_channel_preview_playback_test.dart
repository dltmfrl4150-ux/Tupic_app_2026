import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tupic/features/explore/domain/shared_playback_queue.dart';
import 'package:tupic/features/explore/presentation/shared_catalog_freshness.dart';
import 'package:tupic/features/explore/presentation/shared_catalog_scope.dart';
import 'package:tupic/features/explore/presentation/shared_channel_preview_page.dart';
import 'package:tupic/l10n/app_localizations.dart';
import 'package:tupic/shared/models/share_models.dart';
import 'package:tupic/shared/models/shared_channel_category.dart';
import 'package:tupic/shared/repositories/shared_channel_catalog_repository.dart';

SharePost _publishedPost() {
  return SharePost(
    id: 'p1',
    groupId: 'g1',
    ownerUid: 'u1',
    version: 2,
    title: 'Public Mix',
    category: SharedChannelCategory.music,
    isKids: false,
    videoCount: 3,
    snapshot: const ShareSnapshot(
      channelName: 'Public Mix',
      isKidsChannel: false,
      playOrder: 'oldestAdded',
      videos: [
        ShareSnapshotVideo(
          youtubeVideoId: 'aaa11111111',
          title: 'Song A',
          originalTitle: 'Song A',
          manualOrder: 0,
        ),
        ShareSnapshotVideo(
          youtubeVideoId: 'bbb22222222',
          title: 'Song B',
          originalTitle: 'Song B',
          manualOrder: 1,
        ),
        ShareSnapshotVideo(
          youtubeVideoId: 'ccc33333333',
          title: 'Song C',
          originalTitle: 'Song C',
          manualOrder: 2,
        ),
      ],
    ),
    createdAt: DateTime.utc(2026, 5, 1),
    status: SharePostStatus.published,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('preview exposes play-all and per-video actions', (tester) async {
    final post = _publishedPost();
    final catalog = MemorySharedChannelCatalogRepository(
      posts: [post],
      nicknames: const {'u1': 'Creator'},
    );

    await tester.pumpWidget(
      SharedCatalogScope(
        catalog: catalog,
        freshness: SharedCatalogFreshness(),
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SharedChannelPreviewPage(postId: 'p1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(find.text('전체 재생'), findsOneWidget);
    final playAll = tester.widget<ElevatedButton>(
      find.byKey(const Key('share_preview_play_all')),
    );
    expect(playAll.onPressed, isNotNull);

    expect(find.byKey(const Key('share_preview_video_bbb22222222')), findsOneWidget);
    expect(find.text('채널 추가'), findsOneWidget);
    expect(find.text('내 채널에 영상 추가'), findsOneWidget);

    // Queue plan for the same post (PlayerPage not pumped — YouTube iframe).
    final fromVideo = SharedPlaybackQueue.build(
      post,
      startYoutubeVideoId: 'bbb22222222',
    );
    expect(fromVideo!.initialIndex, 1);
    expect(fromVideo.sessionChannel.id, 'shared_preview__p1');
  });

  testWidgets('empty snapshot disables play all', (tester) async {
    final empty = SharePost(
      id: 'empty',
      groupId: 'g',
      ownerUid: 'u',
      version: 1,
      title: 'Empty',
      category: SharedChannelCategory.other,
      isKids: false,
      videoCount: 0,
      snapshot: const ShareSnapshot(
        channelName: 'Empty',
        isKidsChannel: false,
        playOrder: 'oldestAdded',
        videos: [],
      ),
      createdAt: DateTime.utc(2026, 5, 1),
      status: SharePostStatus.published,
    );
    final catalog = MemorySharedChannelCatalogRepository(posts: [empty]);

    await tester.pumpWidget(
      SharedCatalogScope(
        catalog: catalog,
        freshness: SharedCatalogFreshness(),
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SharedChannelPreviewPage(postId: 'empty'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('share_preview_play_all')),
    );
    expect(button.onPressed, isNull);
  });
}
