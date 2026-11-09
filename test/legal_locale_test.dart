import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tupic/app/app.dart';
import 'package:tupic/app/locale_controller.dart';
import 'package:tupic/core/utils/locale_preference.dart';
import 'package:tupic/features/channels/data/local_channel_repository.dart';
import 'package:tupic/features/home/data/mock_home_repository.dart';
import 'package:tupic/features/legal/data/legal_documents.dart';
import 'package:tupic/features/legal/data/privacy_policy_en.dart';
import 'package:tupic/features/legal/data/terms_of_service_en.dart';
import 'package:tupic/features/legal/data/terms_of_service_ko.dart';
import 'package:tupic/features/legal/domain/legal_document.dart';
import 'package:tupic/features/legal/presentation/consent_panel.dart';
import 'package:tupic/features/legal/presentation/legal_document_page.dart';
import 'package:tupic/features/legal/domain/consent_record.dart';
import 'package:tupic/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('resolveLegalLanguageCode follows app fallback', () {
    expect(resolveLegalLanguageCode(const Locale('ko')), 'ko');
    expect(resolveLegalLanguageCode(const Locale('ko', 'KR')), 'ko');
    expect(resolveLegalLanguageCode(const Locale('en')), 'en');
    expect(resolveLegalLanguageCode(const Locale('ja')), 'en');
    expect(resolveLegalLanguageCode(null), 'en');
  });

  test('English docs keep same versions as Korean sources', () {
    expect(TermsOfServiceEn.version, TermsOfServiceKo.version);
    expect(
      TermsOfServiceEn.version,
      LegalDocumentVersions.termsOfService,
    );
    expect(
      PrivacyPolicyEn.version,
      LegalDocumentVersions.privacyPolicy,
    );
    expect(TermsOfServiceEn.body, contains('Kids Channel'));
    expect(TermsOfServiceEn.body, contains('TODO'));
    expect(PrivacyPolicyEn.body, contains('Firebase Authentication'));
    expect(PrivacyPolicyEn.body, contains('SharedPreferences'));
  });

  test('legalDocumentContent selects by locale without changing versions', () {
    final ko = legalDocumentContent(
      LegalDocumentKind.termsOfService,
      locale: const Locale('ko'),
    );
    final en = legalDocumentContent(
      LegalDocumentKind.termsOfService,
      locale: const Locale('en'),
    );
    expect(ko.languageCode, 'ko');
    expect(en.languageCode, 'en');
    expect(ko.version, en.version);
    expect(ko.body, contains('이용계약'));
    expect(en.body, contains('User Agreement'));
    expect(ko.title, 'TUPICK 이용약관');
    expect(en.title, 'TUPICK Terms of Service');
  });

  Future<void> pumpFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<LocaleController> readyLocale(AppLocalePreference pref) async {
    final controller = LocaleController();
    await controller.load();
    await controller.setPreference(pref);
    return controller;
  }

  testWidgets('settings opens Korean then English legal bodies', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final localeController = await readyLocale(AppLocalePreference.korean);
    await tester.pumpWidget(
      TupicApp(
        localeController: localeController,
        homeRepository: MockHomeRepository(delay: Duration.zero),
        channelRepository: LocalChannelRepository(),
      ),
    );
    await pumpFrames(tester);

    await tester.tap(find.byKey(const Key('home_menu_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('설정'));
    await tester.pump();
    await pumpFrames(tester);

    await tester.ensureVisible(find.byKey(const Key('settings_terms_link')));
    await tester.tap(find.byKey(const Key('settings_terms_link')));
    await pumpFrames(tester);
    expect(find.textContaining('이용계약'), findsOneWidget);
    expect(find.textContaining('User Agreement'), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(LegalDocumentPage),
        matching: find.byTooltip('뒤로'),
      ),
    );
    await tester.pumpAndSettle();

    await localeController.setPreference(AppLocalePreference.english);
    await pumpFrames(tester);

    await tester.ensureVisible(find.byKey(const Key('settings_terms_link')));
    await tester.tap(find.byKey(const Key('settings_terms_link')));
    await pumpFrames(tester);
    expect(find.textContaining('User Agreement'), findsOneWidget);
    expect(find.textContaining('이용계약'), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(LegalDocumentPage),
        matching: find.byTooltip('Back'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('settings_privacy_link')));
    await tester.tap(find.byKey(const Key('settings_privacy_link')));
    await pumpFrames(tester);
    expect(find.textContaining('Information Currently Collected'), findsOneWidget);
  });

  testWidgets('consent View more opens English terms in English locale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ConsentPanel(
            items: defaultLocalConsentItems(
              termsLabel: '[Required] Agree to the Terms of Service',
            ),
            onAccepted: (_) async {},
          ),
        ),
      ),
    );
    await pumpFrames(tester);

    expect(find.text('View more'), findsOneWidget);
    await tester.tap(find.byKey(const Key('consent_view_terms_of_service')));
    await pumpFrames(tester);
    expect(find.textContaining('TUPICK Terms of Service'), findsWidgets);
    expect(find.textContaining('Kids Channel'), findsOneWidget);
  });

  test('adding English docs does not invalidate existing consent version', () {
    final record = ConsentRecord(
      itemId: LegalDocumentIds.termsOfService,
      documentVersion: LegalDocumentVersions.termsOfService,
      acceptedAt: DateTime.utc(2026, 11, 6),
    );
    expect(record.documentVersion, TermsOfServiceEn.version);
    expect(record.documentVersion, TermsOfServiceKo.version);
  });
}
