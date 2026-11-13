import 'package:flutter_test/flutter_test.dart';
import 'package:tupic/shared/models/share_models.dart';
import 'package:tupic/shared/models/shared_channel_category.dart';
import 'package:tupic/shared/repositories/shared_channel_catalog_repository.dart';

SharePost _post({
  required String id,
  required String title,
  SharedChannelCategory category = SharedChannelCategory.other,
  SharePostStatus status = SharePostStatus.published,
  DateTime? createdAt,
  String ownerUid = 'owner',
  int version = 1,
}) {
  return SharePost(
    id: id,
    groupId: 'group',
    ownerUid: ownerUid,
    version: version,
    title: title,
    category: category,
    isKids: false,
    videoCount: 1,
    snapshot: const ShareSnapshot(
      channelName: 'c',
      isKidsChannel: false,
      playOrder: 'manual',
      videos: [
        ShareSnapshotVideo(
          youtubeVideoId: 'v',
          title: 't',
          originalTitle: 't',
          manualOrder: 0,
        ),
      ],
    ),
    createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
    status: status,
  );
}

void main() {
  test('memory catalog excludes cancelled and paginates latest', () async {
    final repo = MemorySharedChannelCatalogRepository(
      posts: [
        _post(
          id: 'a',
          title: 'A',
          createdAt: DateTime.utc(2026, 1, 3),
        ),
        _post(
          id: 'b',
          title: 'B',
          createdAt: DateTime.utc(2026, 1, 2),
        ),
        _post(
          id: 'c',
          title: 'C',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
        _post(
          id: 'x',
          title: 'X',
          status: SharePostStatus.cancelled,
          createdAt: DateTime.utc(2026, 1, 4),
        ),
      ],
      nicknames: const {'owner': 'Nick'},
    );

    final page1 = await repo.listLatest(limit: 2);
    expect(page1.items.map((e) => e.id), ['a', 'b']);
    expect(page1.items.first.ownerNickname, 'Nick');
    expect(page1.hasMore, isTrue);

    final page2 = await repo.listLatest(limit: 2, startAfter: page1.cursor);
    expect(page2.items.map((e) => e.id), ['c']);
    expect(page2.hasMore, isFalse);
  });

  test('memory catalog prefix search and category filter', () async {
    final repo = MemorySharedChannelCatalogRepository(
      posts: [
        _post(
          id: '1',
          title: 'Cool Music',
          category: SharedChannelCategory.music,
        ),
        _post(
          id: '2',
          title: 'Cool Games',
          category: SharedChannelCategory.games,
        ),
        _post(
          id: '3',
          title: 'Other',
          category: SharedChannelCategory.music,
        ),
      ],
    );

    final music = await repo.listLatest(category: SharedChannelCategory.music);
    expect(music.items.map((e) => e.id), ['1', '3']);

    final prefix = await repo.searchPrefix(query: 'Cool');
    expect(prefix.items.map((e) => e.title), ['Cool Games', 'Cool Music']);

    final filtered = await repo.searchPrefix(
      query: 'Cool',
      category: SharedChannelCategory.games,
    );
    expect(filtered.items.single.id, '2');
  });

  test('getPublishedPost ignores cancelled', () async {
    final repo = MemorySharedChannelCatalogRepository(
      posts: [
        _post(id: 'ok', title: 'Ok'),
        _post(
          id: 'no',
          title: 'No',
          status: SharePostStatus.cancelled,
        ),
      ],
    );
    expect((await repo.getPublishedPost('ok'))?.title, 'Ok');
    expect(await repo.getPublishedPost('no'), isNull);
    expect(await repo.getPublishedPost('missing'), isNull);
  });
}
