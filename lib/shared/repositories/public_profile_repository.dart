import '../models/public_profile.dart';

abstract class PublicProfileRepository {
  /// Returns null when the profile document does not exist.
  Future<PublicProfile?> getProfile(String uid);

  /// Creates or updates the caller's public nickname.
  /// Implementations must refuse writes when [uid] is empty / unsigned-in.
  Future<PublicProfile> saveNickname({
    required String uid,
    required String nickname,
  });
}

class PublicProfileException implements Exception {
  const PublicProfileException(this.code, [this.message]);

  final String code;
  final String? message;

  @override
  String toString() => 'PublicProfileException($code)';
}

class ProfileNotSignedInException extends PublicProfileException {
  const ProfileNotSignedInException() : super('not_signed_in');
}

class ProfilePermissionDeniedException extends PublicProfileException {
  const ProfilePermissionDeniedException() : super('permission_denied');
}

class ProfileUnavailableException extends PublicProfileException {
  const ProfileUnavailableException([String? message])
      : super('firestore_unavailable', message);
}

class ProfileInvalidNicknameException extends PublicProfileException {
  const ProfileInvalidNicknameException() : super('invalid_nickname');
}
