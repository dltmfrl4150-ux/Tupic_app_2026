import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tupic/features/player/data/local_playback_progress_repository.dart';
import 'package:tupic/shared/models/channel_playback_progress.dart';
import 'package:tupic/shared/models/play_order.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves and restores per-channel progress independently', () async {
    final repo = LocalPlaybackProgressRepository();
    await repo.saveProgress(
      ChannelPlaybackProgress(
        tupicChannelId: 'ch1',
        youtubeVideoId: 'vidA',
        positionSeconds: 15,
        updatedAt: DateTime(2024, 1, 1),
        sessionQueueIds: const ['vidA', 'vidB'],
        sessionPlayOrder: PlayOrder.shuffle,
      ),
    );
    await repo.saveProgress(
      ChannelPlaybackProgress(
        tupicChannelId: 'ch2',
        youtubeVideoId: 'vidX',
        positionSeconds: 90,
        updatedAt: DateTime(2024, 1, 2),
      ),
    );

    final a = await repo.getProgress('ch1');
    final b = await repo.getProgress('ch2');
    expect(a?.youtubeVideoId, 'vidA');
    expect(a?.positionSeconds, 15);
    expect(a?.sessionQueueIds, ['vidA', 'vidB']);
    expect(b?.youtubeVideoId, 'vidX');
    expect(b?.positionSeconds, 90);
  });

  test('later save overwrites same channel without clobbering others', () async {
    final repo = LocalPlaybackProgressRepository();
    await repo.saveProgress(
      ChannelPlaybackProgress(
        tupicChannelId: 'ch1',
        youtubeVideoId: 'vidA',
        positionSeconds: 1,
        updatedAt: DateTime(2024, 1, 1),
      ),
    );
    await repo.saveProgress(
      ChannelPlaybackProgress(
        tupicChannelId: 'ch2',
        youtubeVideoId: 'vidX',
        positionSeconds: 2,
        updatedAt: DateTime(2024, 1, 1),
      ),
    );
    await repo.saveProgress(
      ChannelPlaybackProgress(
        tupicChannelId: 'ch1',
        youtubeVideoId: 'vidA',
        positionSeconds: 40,
        updatedAt: DateTime(2024, 1, 3),
      ),
    );

    expect((await repo.getProgress('ch1'))?.positionSeconds, 40);
    expect((await repo.getProgress('ch2'))?.positionSeconds, 2);
  });

  test('clearProgress removes only one channel', () async {
    final repo = LocalPlaybackProgressRepository();
    await repo.saveProgress(
      ChannelPlaybackProgress(
        tupicChannelId: 'ch1',
        youtubeVideoId: 'a',
        positionSeconds: 1,
        updatedAt: DateTime(2024),
      ),
    );
    await repo.saveProgress(
      ChannelPlaybackProgress(
        tupicChannelId: 'ch2',
        youtubeVideoId: 'b',
        positionSeconds: 2,
        updatedAt: DateTime(2024),
      ),
    );
    await repo.clearProgress('ch1');
    expect(await repo.getProgress('ch1'), isNull);
    expect(await repo.getProgress('ch2'), isNotNull);
  });

  test('serialized writes stay ordered under overlap', () async {
    final repo = LocalPlaybackProgressRepository();
    final futures = <Future<void>>[];
    for (var i = 0; i < 20; i++) {
      futures.add(
        repo.saveProgress(
          ChannelPlaybackProgress(
            tupicChannelId: 'ch1',
            youtubeVideoId: 'a',
            positionSeconds: i.toDouble(),
            updatedAt: DateTime(2024, 1, 1, 0, 0, i),
          ),
        ),
      );
    }
    await Future.wait(futures);
    final saved = await repo.getProgress('ch1');
    expect(saved?.positionSeconds, 19);
  });
}
