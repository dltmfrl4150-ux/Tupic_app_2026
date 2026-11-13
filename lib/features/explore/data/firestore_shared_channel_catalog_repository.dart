import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/models/share_models.dart';
import '../../../shared/models/shared_channel_category.dart';
import '../../../shared/models/shared_channel_listing.dart';
import '../../../shared/repositories/shared_channel_catalog_repository.dart';
import '../../share/data/firestore_channel_share_repository.dart';

/// Firestore-backed published sharePosts catalog (one-shot queries, no listeners).
class FirestoreSharedChannelCatalogRepository
    implements SharedChannelCatalogRepository {
  FirestoreSharedChannelCatalogRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection(FirestoreChannelShareRepository.postsCollection);

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('publicProfiles');

  @override
  Future<SharedCatalogPage> listLatest({
    SharedChannelCategory category = SharedChannelCategory.all,
    int limit = 20,
    SharedCatalogCursor? startAfter,
  }) async {
    final capped = limit.clamp(1, 50);
    Query<Map<String, dynamic>> query = _posts
        .where('status', isEqualTo: SharePostStatus.published.storageValue);
    if (category != SharedChannelCategory.all) {
      query = query.where('category', isEqualTo: category.name);
    }
    query = query.orderBy('createdAt', descending: true).limit(capped);
    return _runPaged(query, startAfter: startAfter, limit: capped);
  }

  @override
  Future<SharedCatalogPage> searchPrefix({
    required String query,
    SharedChannelCategory category = SharedChannelCategory.all,
    int limit = 20,
    SharedCatalogCursor? startAfter,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return listLatest(
        category: category,
        limit: limit,
        startAfter: startAfter,
      );
    }
    final capped = limit.clamp(1, 50);
    // Prefix range on stored title (case-sensitive). No titleLower field in schema.
    Query<Map<String, dynamic>> q = _posts
        .where('status', isEqualTo: SharePostStatus.published.storageValue);
    if (category != SharedChannelCategory.all) {
      q = q.where('category', isEqualTo: category.name);
    }
    q = q
        .orderBy('title')
        .startAt([trimmed])
        .endAt(['$trimmed\uf8ff'])
        .limit(capped);
    return _runPaged(q, startAfter: startAfter, limit: capped);
  }

  @override
  Future<SharePost?> getPublishedPost(String postId) async {
    if (postId.isEmpty) return null;
    try {
      final snap = await _posts.doc(postId).get();
      if (!snap.exists) return null;
      final post = _postFrom(snap.id, snap.data());
      if (post == null || !post.isPublished) return null;
      return post;
    } on FirebaseException catch (e, st) {
      _logFirebase('getPublishedPost', e, st);
      Error.throwWithStackTrace(_mapFirebase(e), st);
    }
  }

  @override
  Future<Map<String, String>> nicknamesFor(Iterable<String> ownerUids) async {
    final unique = ownerUids.where((u) => u.isNotEmpty).toSet();
    if (unique.isEmpty) return const {};
    final out = <String, String>{};
    // Firestore getAll is not on all platforms the same — batch by doc gets.
    await Future.wait(
      unique.map((uid) async {
        try {
          final snap = await _profiles.doc(uid).get();
          final data = snap.data();
          final nick = data?['nickname'];
          if (nick is String && nick.trim().isNotEmpty) {
            out[uid] = nick.trim();
          }
        } catch (_) {
          // Best-effort; listing still shows without nickname.
        }
      }),
    );
    return out;
  }

  Future<SharedCatalogPage> _runPaged(
    Query<Map<String, dynamic>> query, {
    required SharedCatalogCursor? startAfter,
    required int limit,
  }) async {
    try {
      var q = query;
      final raw = startAfter?.raw;
      if (raw is DocumentSnapshot<Map<String, dynamic>>) {
        q = q.startAfterDocument(raw);
      }
      final snap = await q.get();
      final posts = <SharePost>[];
      for (final doc in snap.docs) {
        final post = _postFrom(doc.id, doc.data());
        if (post != null && post.isPublished) posts.add(post);
      }
      final nicks = await nicknamesFor(posts.map((p) => p.ownerUid));
      final items = posts
          .map(
            (p) => SharedChannelListing.fromSharePost(
              p,
              ownerNickname: nicks[p.ownerUid],
            )!,
          )
          .toList(growable: false);
      final last = snap.docs.isEmpty ? null : snap.docs.last;
      final hasMore = snap.docs.length >= limit;
      return SharedCatalogPage(
        items: items,
        cursor: last == null ? null : SharedCatalogCursor(last),
        hasMore: hasMore,
      );
    } on FirebaseException catch (e, st) {
      _logFirebase('query', e, st);
      Error.throwWithStackTrace(_mapFirebase(e), st);
    }
  }

  static void _logFirebase(String op, FirebaseException e, StackTrace st) {
    if (!kDebugMode) return;
    debugPrint(
      'SharedCatalog $op: code=${e.code} message=${e.message}\n$st',
    );
  }

  /// Maps Firestore errors for UI; exposed for unit tests.
  static SharedCatalogException mapFirebase(FirebaseException e) =>
      _mapFirebase(e);

  static SharedCatalogException _mapFirebase(FirebaseException e) {
    final message = e.message;
    final code = switch (e.code) {
      'failed-precondition'
          when (message ?? '').toLowerCase().contains('index') =>
        SharedCatalogFailureCode.indexRequired,
      'failed-precondition' => SharedCatalogFailureCode.indexRequired,
      'permission-denied' => SharedCatalogFailureCode.permissionDenied,
      'unavailable' || 'deadline-exceeded' => SharedCatalogFailureCode.network,
      _ => SharedCatalogFailureCode.unknown,
    };
    return SharedCatalogException(code, message: message, cause: e);
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
