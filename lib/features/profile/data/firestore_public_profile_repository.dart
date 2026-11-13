import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/public_profile.dart';
import '../../../shared/repositories/public_profile_repository.dart';
import '../domain/nickname_validator.dart';

/// Firestore-backed publicProfiles/{uid}.
class FirestorePublicProfileRepository implements PublicProfileRepository {
  FirestorePublicProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const collectionName = 'publicProfiles';

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(collectionName);

  @override
  Future<PublicProfile?> getProfile(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final snap = await _col.doc(uid).get();
      if (!snap.exists) return null;
      return PublicProfile.fromMap(snap.data(), uid: uid);
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' ||
          e.code == 'not-found' ||
          e.code == 'failed-precondition') {
        throw ProfileUnavailableException(e.message);
      }
      if (e.code == 'permission-denied') {
        throw const ProfilePermissionDeniedException();
      }
      rethrow;
    }
  }

  @override
  Future<PublicProfile> saveNickname({
    required String uid,
    required String nickname,
  }) async {
    if (uid.isEmpty) {
      throw const ProfileNotSignedInException();
    }
    final validated = NicknameValidator.validate(nickname);
    if (!validated.isValid) {
      throw const ProfileInvalidNicknameException();
    }
    final cleaned = validated.nickname!;
    try {
      final ref = _col.doc(uid);
      final existing = await ref.get();
      final payload = <String, dynamic>{
        'uid': uid,
        'nickname': cleaned,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final hasCreatedAt =
          existing.exists && existing.data()?['createdAt'] != null;
      if (!hasCreatedAt) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }
      await ref.set(payload, SetOptions(merge: true));
      final snap = await ref.get();
      return PublicProfile.fromMap(
            snap.data(),
            uid: uid,
            updatedAtFallback: DateTime.now().toUtc(),
          ) ??
          PublicProfile(
            uid: uid,
            nickname: cleaned,
            updatedAt: DateTime.now().toUtc(),
            createdAt: DateTime.now().toUtc(),
          );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const ProfilePermissionDeniedException();
      }
      if (e.code == 'unavailable' ||
          e.code == 'not-found' ||
          e.code == 'failed-precondition') {
        throw ProfileUnavailableException(e.message);
      }
      rethrow;
    }
  }
}
