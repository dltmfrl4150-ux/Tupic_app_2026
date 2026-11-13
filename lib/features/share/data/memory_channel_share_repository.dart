import '../../../shared/models/share_models.dart';
import '../../../shared/models/shared_channel_category.dart';
import '../../../shared/repositories/channel_share_repository.dart';
import '../domain/share_snapshot_builder.dart';

/// In-memory share repository for unit/widget tests.
class MemoryChannelShareRepository implements ChannelShareRepository {
  MemoryChannelShareRepository({this.signedInUid});

  String? signedInUid;

  final Map<String, ShareGroup> _groups = {};
  final Map<String, SharePost> _posts = {};
  var _postSeq = 0;

  @override
  Future<ShareGroup?> findGroup({
    required String ownerUid,
    required String sourceChannelId,
  }) async {
    final id = ShareGroup.documentId(
      ownerUid: ownerUid,
      sourceChannelId: sourceChannelId,
    );
    return _groups[id];
  }

  @override
  Future<SharePost> publish(SharePublishRequest request) async {
    if (signedInUid == null || signedInUid!.isEmpty) {
      throw const ShareNotSignedInException();
    }
    if (request.ownerUid != signedInUid) {
      throw const SharePermissionDeniedException();
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

    final groupId = ShareGroup.documentId(
      ownerUid: request.ownerUid,
      sourceChannelId: request.channel.id,
    );
    final now = DateTime.now().toUtc();
    final existing = _groups[groupId];
    final nextVersion = (existing?.latestVersion ?? 0) + 1;
    final postId = 'post_${++_postSeq}';

    final post = SharePost(
      id: postId,
      groupId: groupId,
      ownerUid: request.ownerUid,
      version: nextVersion,
      title: request.channel.name.trim(),
      description: _cleanDescription(request.description),
      category: request.category,
      isKids: request.channel.isKidsChannel,
      videoCount: built.snapshot!.videos.length,
      snapshot: built.snapshot!,
      createdAt: now,
      status: SharePostStatus.published,
    );

    _posts[postId] = post;
    _groups[groupId] = ShareGroup(
      id: groupId,
      ownerUid: request.ownerUid,
      sourceChannelId: request.channel.id,
      latestVersion: nextVersion,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    return post;
  }

  @override
  Future<List<SharePost>> listMyPosts({
    required String ownerUid,
    int limit = 50,
  }) async {
    final list = _posts.values
        .where((p) => p.ownerUid == ownerUid)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(limit).toList(growable: false);
  }

  @override
  Future<SharePost> cancelPost({
    required String ownerUid,
    required String postId,
  }) async {
    if (signedInUid == null || signedInUid!.isEmpty) {
      throw const ShareNotSignedInException();
    }
    final post = _posts[postId];
    if (post == null) {
      throw const ShareValidationException('not_found');
    }
    if (post.ownerUid != ownerUid || post.ownerUid != signedInUid) {
      throw const SharePermissionDeniedException();
    }
    if (post.status == SharePostStatus.cancelled) {
      return post;
    }
    final updated = SharePost(
      id: post.id,
      groupId: post.groupId,
      ownerUid: post.ownerUid,
      version: post.version,
      title: post.title,
      description: post.description,
      category: post.category,
      isKids: post.isKids,
      videoCount: post.videoCount,
      snapshot: post.snapshot,
      createdAt: post.createdAt,
      status: SharePostStatus.cancelled,
      cancelledAt: DateTime.now().toUtc(),
    );
    _posts[postId] = updated;
    return updated;
  }

  static String? _cleanDescription(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.length > 500 ? trimmed.substring(0, 500) : trimmed;
  }
}
