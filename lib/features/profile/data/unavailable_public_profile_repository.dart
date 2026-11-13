import '../../../shared/models/public_profile.dart';
import '../../../shared/repositories/public_profile_repository.dart';

/// Used when Firebase/Firestore is not initialized on this platform/build.
class UnavailablePublicProfileRepository implements PublicProfileRepository {
  const UnavailablePublicProfileRepository([this.message]);

  final String? message;

  @override
  Future<PublicProfile?> getProfile(String uid) async {
    throw ProfileUnavailableException(message);
  }

  @override
  Future<PublicProfile> saveNickname({
    required String uid,
    required String nickname,
  }) async {
    throw ProfileUnavailableException(message);
  }
}
