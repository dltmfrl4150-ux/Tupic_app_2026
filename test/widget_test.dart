import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tupic/app/app.dart';
import 'package:tupic/app/locale_controller.dart';
import 'package:tupic/core/utils/locale_preference.dart';
import 'package:tupic/features/channels/data/local_channel_repository.dart';
import 'package:tupic/features/channels/presentation/channels_controller.dart';
import 'package:tupic/features/home/data/mock_home_repository.dart';
import 'package:tupic/features/home/presentation/home_controller.dart';
import 'package:tupic/shared/models/content_category.dart';
import 'package:tupic/shared/models/home_feed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<LocaleController> readyLocaleController({
    AppLocalePreference preference = AppLocalePreference.korean,
  }) async {
    final controller = LocaleController();
    await controller.load();
    await controller.setPreference(preference);
    return controller;
  }

  Future<void> pumpFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> openEndDrawer(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('home_menu_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('home opens drawer and navigates to settings', (tester) async {
    final localeController = await readyLocaleController();

    await tester.pumpWidget(
      TupicApp(
        localeController: localeController,
        homeRepository: MockHomeRepository(delay: Duration.zero),
        channelRepository: LocalChannelRepository(),
      ),
    );
    await pumpFrames(tester);

    expect(find.text('TUPICK'), findsWidgets);
    expect(find.text('내 채널'), findsOneWidget);

    await openEndDrawer(tester);
    expect(find.text('채널 목록'), findsOneWidget);

    await tester.tap(find.text('설정'));
    await tester.pump(); // post-frame callback
    await pumpFrames(tester);

    expect(find.text('언어 / Language'), findsOneWidget);
  });

  testWidgets('creates a channel and shows it on home', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localeController = await readyLocaleController();
    final channelRepo = LocalChannelRepository();

    await tester.pumpWidget(
      TupicApp(
        localeController: localeController,
        homeRepository: MockHomeRepository(delay: Duration.zero),
        channelRepository: channelRepo,
      ),
    );
    await pumpFrames(tester);

    await openEndDrawer(tester);
    await tester.tap(find.descendant(
      of: find.byType(Drawer),
      matching: find.text('채널 만들기'),
    ));
    await tester.pump();
    await pumpFrames(tester);

    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), '우리 집 TV');
    await tester.tap(find.widgetWithText(ElevatedButton, '만들기'));
    await pumpFrames(tester);

    expect(find.text('우리 집 TV'), findsWidgets);
    expect(await channelRepo.getChannels(), hasLength(1));
  });

  testWidgets('second channel creation opens premium screen', (tester) async {
    final localeController = await readyLocaleController();
    final channelRepo = LocalChannelRepository(freeMaxChannels: 1);
    await channelRepo.createChannel(name: '기존 채널', isKidsChannel: true);

    await tester.pumpWidget(
      TupicApp(
        localeController: localeController,
        homeRepository: MockHomeRepository(delay: Duration.zero),
        channelRepository: channelRepo,
      ),
    );
    await pumpFrames(tester);

    await openEndDrawer(tester);
    await tester.tap(find.descendant(
      of: find.byType(Drawer),
      matching: find.text('채널 만들기'),
    ));
    await tester.pump();
    await pumpFrames(tester);

    await tester.enterText(find.byType(TextField), '두번째');
    await tester.tap(find.widgetWithText(ElevatedButton, '만들기'));
    await pumpFrames(tester);

    expect(find.text('무료 플랜 채널 제한'), findsOneWidget);
    expect(await channelRepo.getChannels(), hasLength(1));
  });

  test('home controller filters explore videos by category', () async {
    final channels = ChannelsController(
      repository: LocalChannelRepository(),
    );
    await channels.load();
    final controller = HomeController(
      repository: MockHomeRepository(delay: Duration.zero),
      channelsController: channels,
    );
    await controller.load();

    expect(controller.state, isA<HomeFeedReady>());
    final feed = (controller.state as HomeFeedReady).feed;
    expect(feed.exploreByCategory(ContentCategory.all), isNotEmpty);

    controller.selectCategory(ContentCategory.science);
    expect(
      feed.exploreByCategory(ContentCategory.science).every(
        (video) => video.category == ContentCategory.science,
      ),
      isTrue,
    );
  });

  testWidgets('language setting switches UI to English without reset', (
    tester,
  ) async {
    final localeController = await readyLocaleController();

    await tester.pumpWidget(
      TupicApp(
        localeController: localeController,
        homeRepository: MockHomeRepository(delay: Duration.zero),
        channelRepository: LocalChannelRepository(),
      ),
    );
    await pumpFrames(tester);

    expect(find.text('내 채널'), findsOneWidget);

    await openEndDrawer(tester);
    await tester.tap(find.text('설정'));
    await tester.pump();
    await pumpFrames(tester);

    await tester.tap(find.text('English'));
    await pumpFrames(tester);

    expect(find.text('Settings'), findsWidgets);
    expect(localeController.preference, AppLocalePreference.english);

    await tester.pageBack();
    await pumpFrames(tester);

    expect(find.text('My Channels'), findsWidgets);
  });

  testWidgets('unsupported system locale falls back to English', (tester) async {
    final localeController = await readyLocaleController(
      preference: AppLocalePreference.system,
    );
    tester.platformDispatcher.localesTestValue = [const Locale('ja')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      TupicApp(
        localeController: localeController,
        homeRepository: MockHomeRepository(delay: Duration.zero),
        channelRepository: LocalChannelRepository(),
      ),
    );
    await pumpFrames(tester);

    expect(find.text('My Channels'), findsOneWidget);
    expect(find.text('Hello!'), findsOneWidget);
  });

  testWidgets('error demo feed state renders retry', (tester) async {
    final localeController = await readyLocaleController();

    await tester.pumpWidget(
      TupicApp(
        localeController: localeController,
        homeRepository: MockHomeRepository(
          delay: Duration.zero,
          simulateError: true,
        ),
        channelRepository: LocalChannelRepository(),
      ),
    );
    await pumpFrames(tester);
    expect(find.text('문제가 발생했습니다'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('home card body opens channel detail', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localeController = await readyLocaleController();
    final channelRepo = LocalChannelRepository();
    await channelRepo.createChannel(name: '상세 테스트', isKidsChannel: false);

    await tester.pumpWidget(
      TupicApp(
        localeController: localeController,
        homeRepository: MockHomeRepository(delay: Duration.zero),
        channelRepository: channelRepo,
      ),
    );
    await pumpFrames(tester);

    await tester.tap(find.text('상세 테스트').first);
    await pumpFrames(tester);
    expect(find.text('콘텐츠 추가'), findsOneWidget);
  });

  testWidgets('home card play shows empty-queue snackbar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localeController = await readyLocaleController();
    final channelRepo = LocalChannelRepository();
    final channel = await channelRepo.createChannel(
      name: '재생 테스트',
      isKidsChannel: false,
    );

    await tester.pumpWidget(
      TupicApp(
        localeController: localeController,
        homeRepository: MockHomeRepository(delay: Duration.zero),
        channelRepository: channelRepo,
      ),
    );
    await pumpFrames(tester);

    await tester.ensureVisible(find.byKey(Key('channel_card_play_${channel.id}')));
    await tester.tap(find.byKey(Key('channel_card_play_${channel.id}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('재생할 영상이 없습니다'), findsOneWidget);
    expect(find.text('콘텐츠 추가'), findsNothing);
  });

  testWidgets('drawer channel name opens detail', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localeController = await readyLocaleController();
    final channelRepo = LocalChannelRepository();
    final channel = await channelRepo.createChannel(
      name: '드로어 상세',
      isKidsChannel: false,
    );

    await tester.pumpWidget(
      TupicApp(
        localeController: localeController,
        homeRepository: MockHomeRepository(delay: Duration.zero),
        channelRepository: channelRepo,
      ),
    );
    await pumpFrames(tester);

    await openEndDrawer(tester);
    await tester.tap(find.byKey(Key('drawer_channel_${channel.id}')));
    await tester.pump();
    await pumpFrames(tester);
    expect(find.text('콘텐츠 추가'), findsOneWidget);
  });

  testWidgets('drawer play shows empty-queue snackbar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localeController = await readyLocaleController();
    final channelRepo = LocalChannelRepository();
    final channel = await channelRepo.createChannel(
      name: '드로어 재생',
      isKidsChannel: false,
    );

    await tester.pumpWidget(
      TupicApp(
        localeController: localeController,
        homeRepository: MockHomeRepository(delay: Duration.zero),
        channelRepository: channelRepo,
      ),
    );
    await pumpFrames(tester);

    await openEndDrawer(tester);
    await tester.tap(find.byKey(Key('drawer_play_${channel.id}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('재생할 영상이 없습니다'), findsOneWidget);
    expect(find.text('콘텐츠 추가'), findsNothing);
  });
}
