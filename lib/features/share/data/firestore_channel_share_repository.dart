import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/models/share_models.dart';
import '../../../shared/models/shared_channel_category.dart';
import '../../../shared/repositories/channel_share_repository.dart';
import '../domain/share_snapshot_builder.dart';

class FirestoreChannelShareRepository implements ChannelShareRepository {
  FirestoreChannelShareRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const groupsCollection = 'shareGroups';
  static const postsCollection = 'sharePosts';

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection(groupsCollection);

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection(postsCollection);

  @override
  Future<ShareGroup?> findGroup({
    required String ownerUid,
    required String sourceChannelId,
  }) async {
    if (ownerUid.isEmpty || sourceChannelId.isEmpty) return null;
    try {
      final id = ShareGroup.documentId(
        ownerUid: ownerUid,
        sourceChannelId: sourceChannelId,
      );
      final snap = await _groups.doc(id).get();
      if (!snap.exists) return null;
      return _groupFrom(snap.id, snap.data());
    } on FirebaseException catch (e) {
      throw _mapFirebase(e);
    }
  }

  @override
  Future<SharePost> publish(SharePublishRequest request) async {
    if (request.ownerUid.isEmpty) {
      throw const ShareNotSignedInException();
    }
    if (request.category == SharedChannelCategory.all) {
      throw const ShareValidationException('invalid_category');
    }

    final built = ShareSnapshotBuilder.build(
      channel: request.channel,
      videos: request.videos,
      sources: request.sources,
    );
    if (!built.isOk) {
      throw ShareValidationException(built.errorCode!);
    }
    final snapshot = built.snapshot!;
    final description = _cleanDescription(request.description);
    final groupId = ShareGroup.documentId(
      ownerUid: request.ownerUid,
      sourceChannelId: request.channel.id,
    );
    final groupRef = _groups.doc(groupId);
    final postRef = _posts.doc();
    final title = request.channel.name.trim();

    if (kDebugMode) {
      final app = _firestore.app;
      final snapMap = snapshot.toFirestoreMap();
      debugPrint(
        'ChannelShare publish prepare: '
        'projectId=${app.options.projectId} '
        'emulator=${_firestore.settings.host} '
        'authUidLen=${request.ownerUid.length} '
        'groupIdOwnsUidPrefix=${groupId.startsWith('${request.ownerUid}__')} '
        'channelIdLen=${request.channel.id.length} '
        'titleLen=${title.length} '
        'category=${request.category.name} '
        'videoCount=${snapshot.videos.length} '
        'snapshotKeys=${snapMap.keys.toList()} '
        'snapshotTypes=${snapMap.map((k, v) => MapEntry(k, v.runtimeType.toString()))}',
      );
    }

    try {
      final published = await _firestore.runTransaction((tx) async {
        if (kDebugMode) {
          debugPrint('ChannelShare tx: reading group (may be missing)');
        }
        final groupSnap = await tx.get(groupRef);
        var nextVersion = 1;
        if (groupSnap.exists) {
          final data = groupSnap.data();
          final owner = data?['ownerUid'];
          final source = data?['sourceChannelId'];
          if (owner != request.ownerUid || source != request.channel.id) {
            throw const SharePermissionDeniedException();
          }
          final latest = data?['latestVersion'];
          nextVersion = (latest is int ? latest : 0) + 1;
          if (kDebugMode) {
            debugPrint(
              'ChannelShare tx: existing group latestType=${latest.runtimeType} '
              'nextVersion=$nextVersion',
            );
          }
        } else if (kDebugMode) {
          debugPrint('ChannelShare tx: group missing → creating v1');
        }

        // Write group before post; rules validate with getAfter()/existsAfter().
        if (groupSnap.exists) {
          tx.set(
            groupRef,
            {
              'ownerUid': request.ownerUid,
              'sourceChannelId': request.channel.id,
              'latestVersion': nextVersion,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        } else {
          tx.set(groupRef, {
            'ownerUid': request.ownerUid,
            'sourceChannelId': request.channel.id,
            'latestVersion': nextVersion,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        final postData = <String, dynamic>{
          'groupId': groupId,
          'ownerUid': request.ownerUid,
          'version': nextVersion,
          'title': title,
          'category': request.category.name,
          'isKids': request.channel.isKidsChannel,
          'videoCount': snapshot.videos.length,
          'snapshot': snapshot.toFirestoreMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'status': SharePostStatus.published.storageValue,
        };
        if (description != null) {
          postData['description'] = description;
        }
        if (kDebugMode) {
          debugPrint(
            'ChannelShare tx: writing group+post version=$nextVersion '
            'postKeys=${postData.keys.toList()}',
          );
        }
        tx.set(postRef, postData);

        return (
          version: nextVersion,
          createdAtFallback: DateTime.now().toUtc(),
        );
      });

      final saved = await postRef.get();
      final post = _postFrom(saved.id, saved.data()) ??
          SharePost(
            id: postRef.id,
            groupId: groupId,
            ownerUid: request.ownerUid,
            version: published.version,
            title: request.channel.name.trim(),
            description: description,
            category: request.category,
            isKids: request.channel.isKidsChannel,
            videoCount: snapshot.videos.length,
            snapshot: snapshot,
            createdAt: published.createdAtFallback,
            status: SharePostStatus.published,
          );
      return post;
    } on ChannelShareException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebase(e);
    }
  }

  @override
  Future<List<SharePost>> listMyPosts({
    required String ownerUid,
    int limit = 50,
  }) async {
    if (ownerUid.isEmpty) return const [];
    try {
      final capped = limit.clamp(1, 100);
      final query = await _posts
          .where('ownerUid', isEqualTo: ownerUid)
          .limit(capped)
          .get();
      final posts = <SharePost>[];
      for (final doc in query.docs) {
        final post = _postFrom(doc.id, doc.data());
        if (post != null) posts.add(post);
      }
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    } on FirebaseException catch (e) {
      throw _mapFirebase(e);
    }
  }

  @override
  Future<SharePost> cancelPost({
    required String ownerUid,
    required String postId,
  }) async {
    if (ownerUid.isEmpty) {
      throw const ShareNotSignedInException();
    }
    final ref = _posts.doc(postId);
    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) {
          throw const ShareValidationException('not_found');
        }
        final data = snap.data();
        if (data?['ownerUid'] != ownerUid) {
          throw const SharePermissionDeniedException();
        }
        if (data?['status'] == SharePostStatus.cancelled.storageValue) {
          return;
        }
        tx.update(ref, {
          'status': SharePostStatus.cancelled.storageValue,
          'cancelledAt': FieldValue.serverTimestamp(),
        });
      });
      final saved = await ref.get();
      final post = _postFrom(saved.id, saved.data());
      if (post == null) {
        throw const ShareValidationException('not_found');
      }
      return post;
    } on ChannelShareException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebase(e);
    }
  }

  static String? _cleanDescription(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.length > 500 ? trimmed.substring(0, 500) : trimmed;
  }

  static ChannelShareException _mapFirebase(FirebaseException e) {
    if (kDebugMode) {
      // No tokens / full UIDs / video lists.
      debugPrint(
        'ChannelShare Firestore error: code=${e.code} '
        'plugin=${e.plugin} message=${e.message}\n'
        '${StackTrace.current}',
      );
    }
    return switch (e.code) {
      'permission-denied' => const SharePermissionDeniedException(),
      'unavailable' ||
      'not-found' ||
      'failed-precondition' =>
        ShareUnavailableException(e.message),
      _ => ShareUnavailableException(e.message ?? e.code),
    };
  }

  static ShareGroup? _groupFrom(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final ownerUid = data['ownerUid'];
    final sourceChannelId = data['sourceChannelId'];
    final latestVersion = data['latestVersion'];
    if (ownerUid is! String ||
        sourceChannelId is! String ||
        latestVersion is! int) {
      return null;
    }
    return ShareGroup(
      id: id,
      ownerUid: ownerUid,
      sourceChannelId: sourceChannelId,
      latestVersion: latestVersion,
      createdAt: _parseTime(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: _parseTime(data['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static SharePost? _postFrom(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final groupId = data['groupId'];
    final ownerUid = data['ownerUid'];
    final version = data['version'];
    final title = data['title'];
    final categoryRaw = data['category'];
    final videoCount = data['videoCount'];
    final snapshotRaw = data['snapshot'];
    if (groupId is! String ||
        ownerUid is! String ||
        version is! int ||
        title is! String ||
        categoryRaw is! String ||
        videoCount is! int ||
        snapshotRaw is! Map) {
      return null;
    }
    final category = SharedChannelCategory.values.firstWhere(
      (c) => c.name == categoryRaw,
      orElse: () => SharedChannelCategory.other,
    );
    final snapshot =
        ShareSnapshot.fromMap(Map<String, dynamic>.from(snapshotRaw));
    if (snapshot == null) return null;
    return SharePost(
      id: id,
      groupId: groupId,
      ownerUid: ownerUid,
      version: version,
      title: title,
      description:
          data['description'] is String ? data['description'] as String : null,
      category: category,
      isKids: data['isKids'] == true,
      videoCount: videoCount,
      snapshot: snapshot,
      createdAt: _parseTime(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: SharePostStatus.fromStorage(
        data['status'] is String ? data['status'] as String : null,
      ),
      cancelledAt: _parseTime(data['cancelledAt']),
    );
  }

  static DateTime? _parseTime(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
