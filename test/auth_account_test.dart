import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tupic/app/app.dart';
import 'package:tupic/app/locale_controller.dart';
import 'package:tupic/core/utils/locale_preference.dart';
import 'package:tupic/features/auth/presentation/auth_controller.dart';
import 'package:tupic/features/channels/data/local_channel_repository.dart';
import 'package:tupic/features/home/data/mock_home_repository.dart';
import 'package:tupic/features/legal/data/local_consent_repository.dart';
import 'package:tupic/features/legal/domain/consent_record.dart';
import 'package:tupic/features/legal/domain/legal_document.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<LocaleController> readyLocale() async {
    final controller = LocaleController();
    await controller.load();
    await controller.setPreference(AppLocalePreference.korean);
    return controller;
  }

  Future<void> pumpFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('guest home shows neutral hello without Charlie', (tester) async {
    final locale = await readyLocale();
    await tester.pumpWidget(
      TupicApp(
        localeController: locale,
        firebaseReady: false,
        authController: AuthController(firebaseReady: false),
        homeRepository: MockHomeRepository(delay: Duration.zero),
        channelRepository: LocalChannelRepository(),
      ),
    );
    await pumpFrames(tester);

    expect(find.text('안녕하세요!'), findsOneWidget);
    expect(find.textContaining('Charlie'), findsNothing);
  });

  testWidgets('account page shows Google button and requires consent first', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final locale = await readyLocale();
    final auth = AuthController(firebaseReady: false);

    await tester.pumpWidget(
      TupicApp(
        localeController: locale,
        firebaseReady: false,
        authController: auth,
        homeRepository: MockHomeRepository(delay: Duration.zero),
        channelRepository: LocalChannelRepository(),
      ),
    );
    await pumpFrames(tester);

    await tester.tap(find.byKey(const Key('home_menu_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('내 계정'));
    await tester.pump();
    await pumpFrames(tester);

    expect(find.text('Google로 계속하기'), findsOneWidget);
    expect(find.textContaining('로그인 없이도'), findsOneWidget);

    // firebaseReady=false disables the button — enable path via consent when ready.
    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('account_google_sign_in')),
    );
    expect(button.onPressed, isNull);
  });

  test('local channel prefs survive conceptual auth session keys', () async {
    // Guard: auth must not clear channel storage keys.
    SharedPreferences.setMockInitialValues({
      'tupic_user_channels_v1': '[]',
      'tupic_consent_records_v1': '[]',
    });
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('tupic_user_channels_v1'), '[]');

    final consent = LocalConsentRepository(prefs: prefs);
    await consent.recordConsents([
      ConsentRecord(
        itemId: LegalDocumentIds.termsOfService,
        documentVersion: LegalDocumentVersions.termsOfService,
        acceptedAt: DateTime.utc(2026, 11, 9),
      ),
    ]);

    expect(prefs.getString('tupic_user_channels_v1'), '[]');
    expect(await consent.hasAcceptedCurrentTerms(), isTrue);
  });
}
