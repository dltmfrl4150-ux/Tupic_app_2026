import 'package:flutter_test/flutter_test.dart';
import 'package:tupic/features/home/data/mock_home_repository.dart';
import 'package:tupic/shared/models/content_category.dart';
import 'package:tupic/shared/models/home_feed.dart';

void main() {
  test('mock repository returns kids recommendations for kids audience', () async {
    final repo = MockHomeRepository(delay: Duration.zero);
    final feed = await repo.fetchHomeFeed(
      audienceOverride: AudiencePreference.kids,
    );

    expect(feed.isMock, isTrue);
    expect(feed.recommended, isNotEmpty);
    expect(feed.recommended.every((v) => v.isKidsAudience), isTrue);
    expect(
      feed.exploreByCategory(ContentCategory.music),
      isNotEmpty,
    );
  });

  test('mock repository excludes kids-only popularity for general audience', () async {
    final repo = MockHomeRepository(delay: Duration.zero);
    final feed = await repo.fetchHomeFeed(
      audienceOverride: AudiencePreference.general,
    );

    expect(feed.recommended.every((v) => !v.isKidsAudience), isTrue);
    expect(feed.exploreVideos.every((v) => !v.isKidsAudience), isTrue);
  });
}
