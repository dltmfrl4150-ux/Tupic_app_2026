import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tupic/app/locale_controller.dart';
import 'package:tupic/app/theme/tupic_theme.dart';
import 'package:tupic/features/channels/data/local_channel_repository.dart';
import 'package:tupic/features/channels/presentation/channels_controller.dart';
import 'package:tupic/features/content/data/local_content_repository.dart';
import 'package:tupic/features/content/presentation/content_controller.dart';
import 'package:tupic/features/player/domain/playback_session.dart';
import 'package:tupic/l10n/app_localizations.dart';
import 'package:tupic/shared/models/channel_video.dart';
import 'package:tupic/shared/models/content_enums.dart';
import 'package:tupic/shared/models/play_order.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('player strings exist in ko and en', (tester) async {
    for (final locale in const [Locale('ko'), Locale('en')]) {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
      expect(l10n.playerEmptyQueue, isNotEmpty);
      expect(l10n.playerVideoList, isNotEmpty);
      expect(l10n.playerSwitchChannel, isNotEmpty);
      expect(l10n.playerChannelListTitle, isNotEmpty);
      expect(l10n.playerLock, isNotEmpty);
      expect(l10n.playerUnlockHint, isNotEmpty);
      if (locale.languageCode == 'ko') {
        expect(l10n.playerUnlockHint, '길게 눌러 잠금해제');
        expect(l10n.playerSwitchChannel, '채널 전환');
      } else {
        expect(l10n.playerUnlockHint, 'Long press to unlock');
        expect(l10n.playerSwitchChannel, 'Switch channel');
      }
      expect(l10n.playerLastVideo, isNotEmpty);
      expect(l10n.playerVideoUnavailable, isNotEmpty);
      expect(l10n.playChannel, isNotEmpty);
    }
  });

  testWidgets('empty queue shows Korean snackbar guidance', (tester) async {
    final localeController = LocaleController();
    await localeController.load();
    final channels = ChannelsController(
      repository: LocalChannelRepository(),
    );
    await channels.load();
    final created = await channels.createChannel(
      name: 'Play Test',
      isKidsChannel: false,
    );

    final channelRepo = LocalChannelRepository();
    final content = ContentController(
      contentRepository: LocalContentRepository(),
      channelRepository: channelRepo,
      channelsController: channels,
    );
    await content.loadChannel(created.id);

    await tester.pumpWidget(
      LocaleScope(
        controller: localeController,
        child: ChannelsScope(
          controller: channels,
          child: ContentScope(
            controller: content,
            child: MaterialApp(
              theme: TupicTheme.dark(),
              locale: const Locale('ko'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        final queue = content.buildQueue(
                          channelId: created.id,
                          playOrder: PlayOrder.oldestAdded,
                        );
                        final l10n = AppLocalizations.of(context);
                        if (queue.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.playerEmptyQueue)),
                          );
                        }
                      },
                      child: Text(AppLocalizations.of(context).playChannel),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('재생'));
    await tester.pump();
    expect(find.text('재생할 영상이 없습니다'), findsOneWidget);
  });

  test('lock restricts TUPIC controls in session model', () {
    final session = PlaybackSession(
      queue: [
        ChannelVideo(
          youtubeVideoId: 'abcdefghijk',
          tupicChannelId: 'c',
          sourceIds: const ['s'],
          title: 't',
          addedAt: DateTime(2024),
          manualOrder: 0,
          metadataStatus: MetadataStatus.unresolved,
        ),
      ],
      isKidsChannel: true,
    );
    session.setLocked(true);
    expect(session.locked, isTrue);
    expect(session.selectIndex(0), isFalse);
    session.toggleQueuePanel();
    expect(session.queuePanelOpen, isFalse);
  });
}
