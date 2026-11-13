import '../../../shared/models/public_profile.dart';
import '../../../shared/repositories/public_profile_repository.dart';
import '../domain/nickname_validator.dart';

/// In-memory profiles for widget/unit tests (no Firestore).
class MemoryPublicProfileRepository implements PublicProfileRepository {
  MemoryPublicProfileRepository({
    Map<String, PublicProfile>? seed,
    this.signedInUid,
  }) : _profiles = {...?seed};

  final Map<String, PublicProfile> _profiles;

  /// When non-null, only this uid may write (simulates auth rules).
  String? signedInUid;

  @override
  Future<PublicProfile?> getProfile(String uid) async {
    return _profiles[uid];
  }

  @override
  Future<PublicProfile> saveNickname({
    required String uid,
    required String nickname,
  }) async {
    if (signedInUid == null || signedInUid!.isEmpty) {
      throw const ProfileNotSignedInException();
    }
    if (uid != signedInUid) {
      throw const ProfilePermissionDeniedException();
    }
    final validated = NicknameValidator.validate(nickname);
    if (!validated.isValid) {
      throw const ProfileInvalidNicknameException();
    }
    final now = DateTime.now().toUtc();
    final existing = _profiles[uid];
    final profile = PublicProfile(
      uid: uid,
      nickname: validated.nickname!,
      updatedAt: now,
      createdAt: existing?.createdAt ?? now,
    );
    _profiles[uid] = profile;
    return profile;
  }
}
