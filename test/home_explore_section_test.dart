import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tupic/features/explore/presentation/shared_catalog_scope.dart';
import 'package:tupic/features/home/presentation/widgets/home_explore_section.dart';
import 'package:tupic/l10n/app_localizations.dart';
import 'package:tupic/shared/models/share_models.dart';
import 'package:tupic/shared/models/shared_channel_category.dart';
import 'package:tupic/shared/repositories/shared_channel_catalog_repository.dart';

SharePost _post({
  required String id,
  required String title,
  SharedChannelCategory category = SharedChannelCategory.music,
  SharePostStatus status = SharePostStatus.published,
  DateTime? createdAt,
  String ownerUid = 'u1',
}) {
  return SharePost(
    id: id,
    groupId: 'g1',
    ownerUid: ownerUid,
    version: 1,
    title: title,
    category: category,
    isKids: false,
    videoCount: 2,
    snapshot: const ShareSnapshot(
      channelName: 'snap',
      isKidsChannel: false,
      playOrder: 'manual',
      videos: [
        ShareSnapshotVideo(
          youtubeVideoId: 'yt1',
          title: 'V1',
          originalTitle: 'V1',
          manualOrder: 0,
        ),
        ShareSnapshotVideo(
          youtubeVideoId: 'yt2',
          title: 'V2',
          originalTitle: 'V2',
          manualOrder: 1,
        ),
      ],
    ),
    createdAt: createdAt ?? DateTime.utc(2026, 3, 1),
    status: status,
  );
}

void main() {
  testWidgets('home explore section shows search entry, chips, empty state', (
    tester,
  ) async {
    var exploreTaps = 0;
    var searchTaps = 0;

    await tester.pumpWidget(
      SharedCatalogScope(
        catalog: const EmptySharedChannelCatalogRepository(),
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HomeExploreSection(
              onOpenExplore: () => exploreTaps++,
              onOpenSearch: () => searchTaps++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(find.text('채널 탐색'), findsOneWidget);
    expect(find.text('채널 또는 콘텐츠 검색'), findsOneWidget);
    expect(find.text('아직 공유된 채널이 없어요.'), findsOneWidget);
    expect(find.byKey(const Key('home_explore_empty')), findsOneWidget);
    expect(find.text('전체보기'), findsOneWidget);
    expect(find.text('내 콘텐츠 탐색'), findsNothing);

    await tester.tap(find.byKey(const Key('home_explore_view_all')));
    await tester.pump();
    expect(exploreTaps, 1);

    await tester.tap(find.byKey(const Key('home_explore_search_entry')));
    await tester.pump();
    expect(searchTaps, 1);

    expect(
      find.byType(ChoiceChip),
      findsNWidgets(SharedChannelCategory.values.length),
    );
    expect(find.text('전체'), findsOneWidget);
    expect(find.text('키즈'), findsOneWidget);
  });

  testWidgets('home explore shows published shared channel cards', (
    tester,
  ) async {
    final catalog = MemorySharedChannelCatalogRepository(
      posts: [
        _post(id: 'p1', title: 'Alpha Channel'),
        _post(
          id: 'p2',
          title: 'Cancelled',
          status: SharePostStatus.cancelled,
        ),
      ],
      nicknames: const {'u1': '닉네임A'},
    );

    await tester.pumpWidget(
      SharedCatalogScope(
        catalog: catalog,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HomeExploreSection(
              onOpenExplore: () {},
              onOpenSearch: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(find.text('Alpha Channel'), findsOneWidget);
    expect(find.text('닉네임A'), findsOneWidget);
    expect(find.text('Cancelled'), findsNothing);
    expect(find.byKey(const Key('home_explore_empty')), findsNothing);
  });

  testWidgets('narrow layout does not overflow empty explore section', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      SharedCatalogScope(
        catalog: const EmptySharedChannelCatalogRepository(),
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeExploreSection(
                onOpenExplore: () {},
                onOpenSearch: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('home_explore_empty')), findsOneWidget);
  });
}
