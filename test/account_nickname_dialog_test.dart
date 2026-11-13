import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tupic/app/theme/tupic_theme.dart';
import 'package:tupic/features/account/presentation/account_page.dart';
import 'package:tupic/features/auth/presentation/auth_controller.dart';
import 'package:tupic/features/profile/data/memory_public_profile_repository.dart';
import 'package:tupic/features/profile/presentation/public_profile_controller.dart';
import 'package:tupic/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAccount(WidgetTester tester, {
    required AuthController auth,
    required PublicProfileController profile,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TupicTheme.dark(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AuthScope(
          controller: auth,
          child: PublicProfileScope(
            controller: profile,
            child: const AccountPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('nickname save succeeds and returns without framework assert', (
    tester,
  ) async {
    final auth = AuthController(firebaseReady: false);
    auth.debugEmulateSignedIn(uid: 'uid-test', displayName: 'Google Name');
    final repo = MemoryPublicProfileRepository(signedInUid: 'uid-test');
    final profile = PublicProfileController(
      authController: auth,
      repository: repo,
    );
    addTearDown(() {
      profile.dispose();
      auth.dispose();
    });

    await pumpAccount(tester, auth: auth, profile: profile);

    expect(find.byKey(const Key('account_edit_nickname')), findsOneWidget);
    await tester.tap(find.byKey(const Key('account_edit_nickname')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('account_nickname_field')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('account_nickname_field')),
      '튜픽닉네임',
    );
    await tester.tap(find.byKey(const Key('account_nickname_save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(profile.nickname, '튜픽닉네임');
    expect(find.text('공개 닉네임이 저장되었습니다.'), findsOneWidget);
    expect(find.text('튜픽닉네임'), findsWidgets);
  });

  testWidgets('invalid nickname stays in dialog with error', (tester) async {
    final auth = AuthController(firebaseReady: false);
    auth.debugEmulateSignedIn(uid: 'uid-test');
    final repo = MemoryPublicProfileRepository(signedInUid: 'uid-test');
    final profile = PublicProfileController(
      authController: auth,
      repository: repo,
    );
    addTearDown(() {
      profile.dispose();
      auth.dispose();
    });

    await pumpAccount(tester, auth: auth, profile: profile);
    await tester.tap(find.byKey(const Key('account_edit_nickname')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('account_nickname_field')),
      'a',
    );
    await tester.tap(find.byKey(const Key('account_nickname_save')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('account_nickname_field')), findsOneWidget);
    expect(profile.hasNickname, isFalse);
  });

  testWidgets('double tap save does not throw', (tester) async {
    final auth = AuthController(firebaseReady: false);
    auth.debugEmulateSignedIn(uid: 'uid-test');
    final repo = MemoryPublicProfileRepository(signedInUid: 'uid-test');
    final profile = PublicProfileController(
      authController: auth,
      repository: repo,
    );
    addTearDown(() {
      profile.dispose();
      auth.dispose();
    });

    await pumpAccount(tester, auth: auth, profile: profile);
    await tester.tap(find.byKey(const Key('account_edit_nickname')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('account_nickname_field')),
      '두번째닉',
    );

    await tester.tap(find.byKey(const Key('account_nickname_save')));
    // Second tap may miss once the button disables during save — that is OK.
    await tester.tap(
      find.byKey(const Key('account_nickname_save')),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(profile.nickname, '두번째닉');
  });
}
