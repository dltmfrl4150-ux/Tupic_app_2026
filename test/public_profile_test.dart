import 'package:flutter_test/flutter_test.dart';
import 'package:tupic/features/auth/presentation/auth_controller.dart';
import 'package:tupic/features/profile/data/memory_public_profile_repository.dart';
import 'package:tupic/features/profile/domain/nickname_validator.dart';
import 'package:tupic/features/profile/presentation/public_profile_controller.dart';
import 'package:tupic/shared/repositories/public_profile_repository.dart';

void main() {
  group('NicknameValidator', () {
    test('accepts hangul and latin within length', () {
      expect(NicknameValidator.validate('튜픽유저').isValid, isTrue);
      expect(NicknameValidator.validate('Tu').isValid, isTrue);
      expect(NicknameValidator.validate('a' * 20).isValid, isTrue);
    });

    test('rejects empty, short, long, email-like, blocked', () {
      expect(
        NicknameValidator.validate('').error,
        NicknameValidationError.empty,
      );
      expect(
        NicknameValidator.validate('A').error,
        NicknameValidationError.tooShort,
      );
      expect(
        NicknameValidator.validate('a' * 21).error,
        NicknameValidationError.tooLong,
      );
      expect(
        NicknameValidator.validate('user@email.com').error,
        NicknameValidationError.invalidCharacters,
      );
      expect(
        NicknameValidator.validate('admin').error,
        NicknameValidationError.inappropriate,
      );
    });

    test('trims and collapses spaces', () {
      final result = NicknameValidator.validate('  별  나들이  ');
      expect(result.isValid, isTrue);
      expect(result.nickname, '별 나들이');
    });

    test('allows duplicate nicknames conceptually (no uniqueness check)', () {
      final a = NicknameValidator.validate('같은이름');
      final b = NicknameValidator.validate('같은이름');
      expect(a.nickname, b.nickname);
    });
  });

  group('MemoryPublicProfileRepository', () {
    test('creates and updates nickname for signed-in owner', () async {
      final repo = MemoryPublicProfileRepository(signedInUid: 'uid-1');
      final created = await repo.saveNickname(uid: 'uid-1', nickname: '첫닉');
      expect(created.nickname, '첫닉');
      final updated = await repo.saveNickname(uid: 'uid-1', nickname: '둘째닉');
      expect(updated.nickname, '둘째닉');
      expect((await repo.getProfile('uid-1'))?.nickname, '둘째닉');
    });

    test('rejects other user and signed-out writes', () async {
      final repo = MemoryPublicProfileRepository(signedInUid: 'uid-1');
      await expectLater(
        repo.saveNickname(uid: 'uid-2', nickname: '해커'),
        throwsA(isA<ProfilePermissionDeniedException>()),
      );
      repo.signedInUid = null;
      await expectLater(
        repo.saveNickname(uid: 'uid-1', nickname: '해커'),
        throwsA(isA<ProfileNotSignedInException>()),
      );
    });
  });

  group('PublicProfileController', () {
    test('saveNickname requires sign-in and does not use Google name', () async {
      final auth = AuthController(firebaseReady: false);
      final repo = MemoryPublicProfileRepository(signedInUid: null);
      final controller = PublicProfileController(
        authController: auth,
        repository: repo,
      );
      addTearDown(controller.dispose);

      expect(await controller.saveNickname('내닉네임'), isFalse);
      expect(controller.errorCode, 'not_signed_in');
      // Google displayName is never auto-published by the controller API.
      expect(controller.nickname, isNull);
    });

    test('saves when repository allows current uid', () async {
      final auth = AuthController(firebaseReady: false);
      auth.debugSyncPremiumForUid(null);
      final repo = MemoryPublicProfileRepository(signedInUid: 'test-uid');
      // Simulate signed-in without Firebase by saving via repo + refresh path:
      final profile = await repo.saveNickname(uid: 'test-uid', nickname: '테스트');
      expect(profile.nickname, '테스트');

      final controller = PublicProfileController(
        authController: auth,
        repository: repo,
      );
      addTearDown(controller.dispose);
      // Not signed in via AuthController — nicknameForUid still works.
      expect(await controller.nicknameForUid('test-uid'), '테스트');
    });
  });
}
