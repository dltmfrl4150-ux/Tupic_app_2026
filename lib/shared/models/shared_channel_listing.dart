import 'share_models.dart';
import 'shared_channel_category.dart';

/// Card/list row for a published shared channel (explore catalog).
class SharedChannelListing {
  const SharedChannelListing({
    required this.id,
    required this.title,
    required this.ownerUid,
    required this.category,
    required this.publishedAt,
    required this.version,
    required this.isKids,
    this.videoCount = 0,
    this.ownerNickname,
    this.description,
  });

  /// sharePosts document id.
  final String id;
  final String title;

  /// Author uid — display via [ownerNickname] when resolved.
  final String ownerUid;
  final String? ownerNickname;
  final SharedChannelCategory category;
  final DateTime publishedAt;
  final int videoCount;
  final int version;
  final bool isKids;
  final String? description;

  String get displayAuthor =>
      (ownerNickname != null && ownerNickname!.trim().isNotEmpty)
          ? ownerNickname!.trim()
          : '—';

  SharedChannelListing copyWith({
    String? ownerNickname,
  }) {
    return SharedChannelListing(
      id: id,
      title: title,
      ownerUid: ownerUid,
      ownerNickname: ownerNickname ?? this.ownerNickname,
      category: category,
      publishedAt: publishedAt,
      videoCount: videoCount,
      version: version,
      isKids: isKids,
      description: description,
    );
  }

  static SharedChannelListing? fromSharePost(
    SharePost post, {
    String? ownerNickname,
  }) {
    if (!post.isPublished) return null;
    return SharedChannelListing(
      id: post.id,
      title: post.title,
      ownerUid: post.ownerUid,
      ownerNickname: ownerNickname,
      category: post.category,
      publishedAt: post.createdAt,
      videoCount: post.videoCount,
      version: post.version,
      isKids: post.isKids,
      description: post.description,
    );
  }
}

/// Opaque pagination cursor (Firestore DocumentSnapshot wrapped by catalog impl).
class SharedCatalogCursor {
  const SharedCatalogCursor(this.raw);

  final Object raw;
}

class SharedCatalogPage {
  const SharedCatalogPage({
    required this.items,
    this.cursor,
    this.hasMore = false,
  });

  final List<SharedChannelListing> items;
  final SharedCatalogCursor? cursor;
  final bool hasMore;

  static const empty = SharedCatalogPage(items: []);
}
