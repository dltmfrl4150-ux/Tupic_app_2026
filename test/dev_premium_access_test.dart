import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tupic/core/config/dev_premium_access.dart';
import 'package:tupic/core/constants/plan_limits.dart';
import 'package:tupic/features/auth/presentation/auth_controller.dart';
import 'package:tupic/features/channels/data/local_channel_repository.dart';
import 'package:tupic/shared/repositories/channel_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const allow = ['dev-uid-alpha', 'dev-uid-beta'];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlanLimits.debugResetDeveloperTestPremium();
  });

  tearDown(() {
    PlanLimits.debugResetDeveloperTestPremium();
  });

  group('hasDevPremiumTestAccess', () {
    test('debug + allow-listed UID → true', () {
      expect(
        hasDevPremiumTestAccess(
          firebaseUid: 'dev-uid-alpha',
          debugModeOverride: true,
          allowedUidsOverride: allow,
        ),
        isTrue,
      );
    });

    test('debug + other UID → false', () {
      expect(
        hasDevPremiumTestAccess(
          firebaseUid: 'regular-uid',
          debugModeOverride: true,
          allowedUidsOverride: allow,
        ),
        isFalse,
      );
    });

    test('release-like (non-debug) + allow-listed UID → false', () {
      expect(
        hasDevPremiumTestAccess(
          firebaseUid: 'dev-uid-alpha',
          debugModeOverride: false,
          allowedUidsOverride: allow,
        ),
        isFalse,
      );
    });

    test('debug + null/empty UID → false', () {
      expect(
        hasDevPremiumTestAccess(
          firebaseUid: null,
          debugModeOverride: true,
          allowedUidsOverride: allow,
        ),
        isFalse,
      );
      expect(
        hasDevPremiumTestAccess(
          firebaseUid: '  ',
          debugModeOverride: true,
          allowedUidsOverride: allow,
        ),
        isFalse,
      );
    });

    test('parses comma-separated define string', () {
      expect(
        configuredDevPremiumUids(rawOverride: ' a ,b, ,c '),
        ['a', 'b', 'c'],
      );
    });
  });

  test('developer premium raises channel limit; logout clears it', () async {
    final repo = LocalChannelRepository(freeMaxChannels: 1);
    final auth = AuthController(
      firebaseReady: false,
      devPremiumUidAllowList: allow,
    );

    auth.debugSyncPremiumForUid('dev-uid-alpha');
    expect(PlanLimits.isPremium, isTrue);
    expect(auth.isDeveloperTestPremium, isTrue);
    expect(kDebugMode, isTrue); // unit tests run as debug

    await repo.createChannel(name: 'Kids', isKidsChannel: true);
    await repo.createChannel(name: 'General', isKidsChannel: false);
    expect(await repo.getChannels(), hasLength(2));

    auth.debugSyncPremiumForUid(null);
    expect(PlanLimits.isPremium, isFalse);
    expect(auth.isDeveloperTestPremium, isFalse);

    expect(
      () => repo.createChannel(name: 'Third', isKidsChannel: true),
      throwsA(isA<ChannelLimitExceededException>()),
    );

    auth.dispose();
  });

  test('free user stays at one channel', () async {
    final repo = LocalChannelRepository(freeMaxChannels: 1);
    expect(PlanLimits.isPremium, isFalse);
    await repo.createChannel(name: 'Only', isKidsChannel: true);
    expect(
      () => repo.createChannel(name: 'Two', isKidsChannel: false),
      throwsA(isA<ChannelLimitExceededException>()),
    );
  });
}
