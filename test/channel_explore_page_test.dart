import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tupic/features/auth/presentation/auth_controller.dart';
import 'package:tupic/features/channels/data/local_channel_repository.dart';
import 'package:tupic/features/channels/presentation/channels_controller.dart';
import 'package:tupic/features/explore/presentation/channel_explore_page.dart';
import 'package:tupic/features/explore/presentation/select_channel_to_share_page.dart';
import 'package:tupic/features/explore/presentation/shared_catalog_scope.dart';
import 'package:tupic/features/explore/presentation/shared_channel_preview_page.dart';
import 'package:tupic/features/profile/data/memory_public_profile_repository.dart';
import 'package:tupic/features/profile/presentation/public_profile_controller.dart';
import 'package:tupic/features/share/data/memory_channel_share_repository.dart';
import 'package:tupic/features/share/presentation/channel_share_controller.dart';
import 'package:tupic/features/share/presentation/my_shared_channels_page.dart';
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
    videoCount: 1,
    snapshot: const ShareSnapshot(
      channelName: 'snap',
      isKidsChannel: false,
      playOrder: 'manual',
      videos: [
        ShareSnapshotVideo(
          youtubeVideoId: 'yt1',
          title: 'Song One',
          originalTitle: 'Song One',
          manualOrder: 0,
        ),
      ],
    ),
    createdAt: createdAt ?? DateTime.utc(2026, 3, 1),
    status: status,
  );
}

Widget _wrapExplore(
  Widget child, {
  SharedChannelCatalogRepository? catalog,
  AuthController? auth,
  PublicProfileController? profile,
  ChannelsController? channels,
  ChannelShareController? share,
}) {
  // Scopes must wrap MaterialApp so pushed routes (preview / share) inherit them.
  Widget tree = MaterialApp(
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
  tree = SharedCatalogScope(
    catalog: catalog ?? const EmptySharedChannelCatalogRepository(),
    child: tree,
  );
  if (channels != null) {
    tree = ChannelsScope(controller: channels, child: tree);
  }
  if (share != null) {
    tree = ChannelShareScope(controller: share, child: tree);
  }
  if (profile != null) {
    tree = PublicProfileScope(controller: profile, child: tree);
  }
  if (auth != null) {
    tree = AuthScope(controller: auth, child: tree);
  }
  return tree;
}

/// Avoid pumpAndSettle while a CircularProgressIndicator may be on screen.
Future<void> _pumpLoad(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('explore page shows empty state and share actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapExplore(
        const ChannelExplorePage(
          catalog: EmptySharedChannelCatalogRepository(),
        ),
      ),
    );
    await _pumpLoad(tester);

    expect(find.text('채널 탐색'), findsWidgets);
    expect(find.text('아직 공유된 채널이 없어요.'), findsOneWidget);
    expect(find.text('첫 번째 채널을 공유해 보세요!'), findsOneWidget);
    expect(find.text('내 채널 공유하기'), findsOneWidget);
    expect(find.text('공유한 내 채널'), findsOneWidget);
  });

  testWidgets('explore lists published posts and opens preview', (tester) async {
    final catalog = MemorySharedChannelCatalogRepository(
      posts: [
        _post(id: 'p1', title: 'Beta Live'),
        _post(
          id: 'p2',
          title: 'Hidden',
          status: SharePostStatus.cancelled,
        ),
      ],
      nicknames: const {'u1': '작성자B'},
    );

    await tester.pumpWidget(
      _wrapExplore(
        ChannelExplorePage(catalog: catalog),
        catalog: catalog,
      ),
    );
    await _pumpLoad(tester);

    expect(find.text('Beta Live'), findsOneWidget);
    expect(find.text('Hidden'), findsNothing);
    expect(find.textContaining('작성자B'), findsOneWidget);

    await tester.tap(find.text('Beta Live'));
    await _pumpLoad(tester);

    expect(find.byType(SharedChannelPreviewPage), findsOneWidget);
    expect(find.text('Song One'), findsOneWidget);
    expect(find.text('채널 추가'), findsOneWidget);
    expect(find.text('내 채널에 영상 추가'), findsOneWidget);
  });

  testWidgets('category filter and prefix search', (tester) async {
    final catalog = MemorySharedChannelCatalogRepository(
      posts: [
        _post(
          id: 'p1',
          title: 'Alpha Music',
          category: SharedChannelCategory.music,
          createdAt: DateTime.utc(2026, 3, 2),
        ),
        _post(
          id: 'p2',
          title: 'Alpha Games',
          category: SharedChannelCategory.games,
          createdAt: DateTime.utc(2026, 3, 3),
        ),
        _post(
          id: 'p3',
          title: 'Zeta Music',
          category: SharedChannelCategory.music,
          createdAt: DateTime.utc(2026, 3, 1),
        ),
      ],
    );

    await tester.pumpWidget(
      _wrapExplore(
        ChannelExplorePage(catalog: catalog),
        catalog: catalog,
      ),
    );
    await _pumpLoad(tester);

    expect(find.text('Alpha Music'), findsOneWidget);
    expect(find.text('Alpha Games'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '게임'));
    await _pumpLoad(tester);
    expect(find.text('Alpha Games'), findsOneWidget);
    expect(find.text('Alpha Music'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, '전체'));
    await _pumpLoad(tester);

    await tester.enterText(
      find.byKey(const Key('explore_search_field')),
      'Alpha',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await _pumpLoad(tester);

    expect(find.text('Alpha Music'), findsOneWidget);
    expect(find.text('Alpha Games'), findsOneWidget);
    expect(find.text('Zeta Music'), findsNothing);
  });

  testWidgets('share my channel opens channel picker page', (tester) async {
    final channels = ChannelsController(repository: LocalChannelRepository());
    await channels.load();
    addTearDown(channels.dispose);

    await tester.pumpWidget(
      _wrapExplore(
        const ChannelExplorePage(
          catalog: EmptySharedChannelCatalogRepository(),
        ),
        channels: channels,
      ),
    );
    await _pumpLoad(tester);

    await tester.tap(find.byKey(const Key('explore_share_my_channel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(SelectChannelToSharePage), findsOneWidget);
    expect(find.textContaining('공유할 채널이 없어요'), findsOneWidget);
  });

  testWidgets('my shared channels opens management page', (tester) async {
    final auth = AuthController(firebaseReady: false);
    final profile = PublicProfileController(
      authController: auth,
      repository: MemoryPublicProfileRepository(),
    );
    final share = ChannelShareController(
      authController: auth,
      profileController: profile,
      repository: MemoryChannelShareRepository(),
    );
    addTearDown(() {
      share.dispose();
      profile.dispose();
      auth.dispose();
    });

    await tester.pumpWidget(
      _wrapExplore(
        const ChannelExplorePage(
          catalog: EmptySharedChannelCatalogRepository(),
        ),
        auth: auth,
        profile: profile,
        share: share,
      ),
    );
    await _pumpLoad(tester);

    await tester.tap(find.byKey(const Key('explore_my_shared_channels')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(MySharedChannelsPage), findsOneWidget);
  });
}
