import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tupic/app/app.dart';
import 'package:tupic/app/locale_controller.dart';
import 'package:tupic/core/utils/locale_preference.dart';
import 'package:tupic/features/channels/data/local_channel_repository.dart';
import 'package:tupic/features/home/data/mock_home_repository.dart';
import 'package:tupic/features/legal/data/local_consent_repository.dart';
import 'package:tupic/features/legal/data/privacy_policy_ko.dart';
import 'package:tupic/features/legal/data/terms_of_service_ko.dart';
import 'package:tupic/features/legal/domain/consent_record.dart';
import 'package:tupic/features/legal/domain/legal_document.dart';
import 'package:tupic/features/legal/presentation/consent_panel.dart';
import 'package:tupic/features/legal/presentation/legal_document_page.dart';
import 'package:tupic/l10n/app_localizations.dart';

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

  test('terms and privacy drafts include required policy points', () {
    expect(TermsOfServiceKo.body, contains('YouTube'));
    expect(TermsOfServiceKo.body, contains('키즈 채널'));
    expect(TermsOfServiceKo.body, contains('보증하는 기능이 아닙니다'));
    expect(TermsOfServiceKo.body, contains('출시 전 확인 필요'));
    expect(PrivacyPolicyKo.body, contains('SharedPreferences'));
    expect(PrivacyPolicyKo.body, contains('현재 수집'));
    expect(PrivacyPolicyKo.body, contains('향후 Google 로그인'));
    expect(PrivacyPolicyKo.body, contains('Firebase Authentication'));
    expect(PrivacyPolicyKo.body, contains('TODO'));
  });

  test('consent repository stores only explicit records', () async {
    final repo = LocalConsentRepository();
    expect(await repo.hasAcceptedCurrentTerms(), isFalse);

    await repo.recordConsents([
      ConsentRecord(
        itemId: LegalDocumentIds.termsOfService,
        documentVersion: LegalDocumentVersions.termsOfService,
        acceptedAt: DateTime.utc(2026, 11, 6),
      ),
    ]);

    expect(await repo.hasAcceptedCurrentTerms(), isTrue);
    final records = await repo.loadRecords();
    expect(records, hasLength(1));
    expect(records.single.itemId, LegalDocumentIds.termsOfService);
  });

  testWidgets('consent continue disabled until required checked; view does not save', (
    tester,
  ) async {
    final repo = LocalConsentRepository();
    var accepted = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ConsentPanel(
            repository: repo,
            items: defaultLocalConsentItems(
              termsLabel: '[필수] 이용약관 동의',
            ),
            onAccepted: (_) async {
              accepted = true;
            },
          ),
        ),
      ),
    );
    await pumpFrames(tester);

    final continueBtn = find.byKey(const Key('consent_continue_button'));
    expect(tester.widget<ElevatedButton>(continueBtn).onPressed, isNull);

    await tester.tap(find.byKey(const Key('consent_view_terms_of_service')));
    await pumpFrames(tester);
    expect(find.textContaining('TUPICK 이용약관'), findsWidgets);
    expect(await repo.hasAcceptedCurrentTerms(), isFalse);
    expect(accepted, isFalse);

    await tester.tap(
      find.descendant(
        of: find.byType(LegalDocumentPage),
        matching: find.byTooltip('뒤로'),
      ),
    );
    await pumpFrames(tester);

    await tester.tap(find.byKey(const Key('consent_check_terms_of_service')));
    await pumpFrames(tester);
    expect(tester.widget<ElevatedButton>(continueBtn).onPressed, isNotNull);

    await tester.tap(continueBtn);
    await pumpFrames(tester);

    expect(accepted, isTrue);
    expect(await repo.hasAcceptedCurrentTerms(), isTrue);
  });

  testWidgets('settings opens terms and privacy; home has no consent popup', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localeController = await readyLocale();

    await tester.pumpWidget(
      TupicApp(
        localeController: localeController,
        homeRepository: MockHomeRepository(delay: Duration.zero),
        channelRepository: LocalChannelRepository(),
      ),
    );
    await pumpFrames(tester);

    expect(find.text('TUPICK 서비스 이용 안내'), findsNothing);

    await tester.tap(find.byKey(const Key('home_menu_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('설정'));
    await tester.pump();
    await pumpFrames(tester);

    expect(find.text('약관 및 개인정보'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('settings_terms_link')));
    await tester.tap(find.byKey(const Key('settings_terms_link')));
    await pumpFrames(tester);
    expect(find.byType(LegalDocumentPage), findsOneWidget);
    expect(find.textContaining('이용계약'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(LegalDocumentPage),
        matching: find.byTooltip('뒤로'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('settings_privacy_link')));
    await tester.tap(find.byKey(const Key('settings_privacy_link')));
    await pumpFrames(tester);
    expect(find.textContaining('현재 수집'), findsOneWidget);
  });
}
