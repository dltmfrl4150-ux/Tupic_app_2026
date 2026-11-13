import '../models/share_models.dart';
import '../models/shared_channel_category.dart';
import '../models/shared_channel_listing.dart';

/// Why a catalog query failed (mapped from Firestore / network).
enum SharedCatalogFailureCode {
  /// Composite index missing (Firestore failed-precondition + index message).
  indexRequired,

  /// Security rules blocked the query/document.
  permissionDenied,

  /// Transient connectivity / backend availability.
  network,

  /// Anything else (including parse/state surprises).
  unknown,
}

class SharedCatalogException implements Exception {
  const SharedCatalogException(
    this.code, {
    this.message,
    this.cause,
  });

  final SharedCatalogFailureCode code;
  final String? message;
  final Object? cause;

  @override
  String toString() =>
      'SharedCatalogException($code${message == null ? '' : ': $message'})';
}

/// Read-only catalog of published shared channels (explore / home).
abstract class SharedChannelCatalogRepository {
  /// Latest published posts (optional category). Home uses a small [limit].
  Future<SharedCatalogPage> listLatest({
    SharedChannelCategory category = SharedChannelCategory.all,
    int limit = 20,
    SharedCatalogCursor? startAfter,
  });

  /// Title prefix search on published posts (case-sensitive as stored).
  Future<SharedCatalogPage> searchPrefix({
    required String query,
    SharedChannelCategory category = SharedChannelCategory.all,
    int limit = 20,
    SharedCatalogCursor? startAfter,
  });

  /// Full published post for preview (null if missing/cancelled).
  Future<SharePost?> getPublishedPost(String postId);

  /// Resolves public nicknames for owner uids (best-effort, may omit misses).
  Future<Map<String, String>> nicknamesFor(Iterable<String> ownerUids);
}

/// Empty catalog — used when Firebase/Firestore is unavailable.
class EmptySharedChannelCatalogRepository
    implements SharedChannelCatalogRepository {
  const EmptySharedChannelCatalogRepository();

  @override
  Future<SharedCatalogPage> listLatest({
    SharedChannelCategory category = SharedChannelCategory.all,
    int limit = 20,
    SharedCatalogCursor? startAfter,
  }) async =>
      SharedCatalogPage.empty;

  @override
  Future<SharedCatalogPage> searchPrefix({
    required String query,
    SharedChannelCategory category = SharedChannelCategory.all,
    int limit = 20,
    SharedCatalogCursor? startAfter,
  }) async =>
      SharedCatalogPage.empty;

  @override
  Future<SharePost?> getPublishedPost(String postId) async => null;

  @override
  Future<Map<String, String>> nicknamesFor(Iterable<String> ownerUids) async =>
      const {};
}

/// In-memory catalog for widget/unit tests (no fake production data).
class MemorySharedChannelCatalogRepository
    implements SharedChannelCatalogRepository {
  MemorySharedChannelCatalogRepository({
    List<SharePost>? posts,
    Map<String, String>? nicknames,
  })  : _posts = List<SharePost>.from(posts ?? const []),
        _nicknames = Map<String, String>.from(nicknames ?? const {});

  final List<SharePost> _posts;
  final Map<String, String> _nicknames;

  /// Test helper: replace in-memory posts (e.g. simulate cancel).
  void replacePosts(List<SharePost> posts) {
    _posts
      ..clear()
      ..addAll(posts);
  }

  List<SharePost> get _published =>
      _posts.where((p) => p.isPublished).toList(growable: false);

  @override
  Future<SharedCatalogPage> listLatest({
    SharedChannelCategory category = SharedChannelCategory.all,
    int limit = 20,
    SharedCatalogCursor? startAfter,
  }) async {
    var list = _published;
    if (category != SharedChannelCategory.all) {
      list = list.where((p) => p.category == category).toList(growable: false);
    }
    list = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final start = startAfter?.raw is int ? startAfter!.raw as int : 0;
    final slice = list.skip(start).take(limit).toList(growable: false);
    final next = start + slice.length;
    return SharedCatalogPage(
      items: slice
          .map(
            (p) => SharedChannelListing.fromSharePost(
              p,
              ownerNickname: _nicknames[p.ownerUid],
            )!,
          )
          .toList(growable: false),
      cursor: next < list.length ? SharedCatalogCursor(next) : null,
      hasMore: next < list.length,
    );
  }

  @override
  Future<SharedCatalogPage> searchPrefix({
    required String query,
    SharedChannelCategory category = SharedChannelCategory.all,
    int limit = 20,
    SharedCatalogCursor? startAfter,
  }) async {
    final q = query.trim();
    if (q.isEmpty) {
      return listLatest(
        category: category,
        limit: limit,
        startAfter: startAfter,
      );
    }
    var list = _published.where((p) => p.title.startsWith(q));
    if (category != SharedChannelCategory.all) {
      list = list.where((p) => p.category == category);
    }
    final sorted = list.toList(growable: false)
      ..sort((a, b) => a.title.compareTo(b.title));
    final start = startAfter?.raw is int ? startAfter!.raw as int : 0;
    final slice = sorted.skip(start).take(limit).toList(growable: false);
    final next = start + slice.length;
    return SharedCatalogPage(
      items: slice
          .map(
            (p) => SharedChannelListing.fromSharePost(
              p,
              ownerNickname: _nicknames[p.ownerUid],
            )!,
          )
          .toList(growable: false),
      cursor: next < sorted.length ? SharedCatalogCursor(next) : null,
      hasMore: next < sorted.length,
    );
  }

  @override
  Future<SharePost?> getPublishedPost(String postId) async {
    try {
      final post = _posts.firstWhere((p) => p.id == postId);
      return post.isPublished ? post : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, String>> nicknamesFor(Iterable<String> ownerUids) async {
    final out = <String, String>{};
    for (final uid in ownerUids) {
      final nick = _nicknames[uid];
      if (nick != null && nick.isNotEmpty) out[uid] = nick;
    }
    return out;
  }
}
