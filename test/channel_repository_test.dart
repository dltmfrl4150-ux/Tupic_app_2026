import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tupic/core/utils/parental_gate.dart';
import 'package:tupic/features/channels/data/local_channel_repository.dart';
import 'package:tupic/shared/models/play_order.dart';
import 'package:tupic/shared/repositories/channel_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('creates, renames, updates play order, and deletes channel', () async {
    final repo = LocalChannelRepository();

    final created = await repo.createChannel(
      name: '  우주 채널  ',
      isKidsChannel: true,
    );
    expect(created.name, '우주 채널');
    expect(created.isKidsChannel, isTrue);
    expect(created.playOrder, PlayOrder.oldestAdded);
    expect(await repo.getLastSelectedChannelId(), created.id);

    final renamed = await repo.renameChannel(id: created.id, name: '탐험 채널');
    expect(renamed.name, '탐험 채널');

    final shuffled = await repo.updatePlayOrder(
      id: created.id,
      playOrder: PlayOrder.shuffle,
    );
    expect(shuffled.playOrder, PlayOrder.shuffle);

    final titled = await repo.updatePlayOrder(
      id: created.id,
      playOrder: PlayOrder.titleAsc,
    );
    expect(titled.playOrder, PlayOrder.titleAsc);

    final prefs = await SharedPreferences.getInstance();
    final reloaded = LocalChannelRepository(prefs: prefs);
    final restored = (await reloaded.getChannels()).single;
    expect(restored.playOrder, PlayOrder.titleAsc);

    await repo.deleteChannel(created.id);
    expect(await repo.getChannels(), isEmpty);
    expect(await repo.getLastSelectedChannelId(), isNull);
  });

  test('enforces free plan channel limit', () async {
    final repo = LocalChannelRepository(freeMaxChannels: 1);
    await repo.createChannel(name: '첫 채널', isKidsChannel: true);

    expect(
      () => repo.createChannel(name: '둘째', isKidsChannel: false),
      throwsA(isA<ChannelLimitExceededException>()),
    );
  });

  test('rejects blank channel names', () async {
    final repo = LocalChannelRepository();
    expect(
      () => repo.createChannel(name: '   ', isKidsChannel: true),
      throwsA(isA<InvalidChannelNameException>()),
    );
  });

  test('survives corrupt local payload', () async {
    SharedPreferences.setMockInitialValues({
      'tupic_user_channels_v1': '{not-json',
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalChannelRepository(prefs: prefs);
    expect(await repo.getChannels(), isEmpty);
  });

  test('parental gate accepts ages 18+', () {
    final now = DateTime(2026, 11, 5);
    expect(passesParentalGate(2008, now: now), isTrue);
    expect(passesParentalGate(2009, now: now), isFalse);
    expect(passesParentalGate(1899, now: now), isFalse);
    expect(parseBirthYear('2000'), 2000);
    expect(parseBirthYear('20'), isNull);
  });
}
