import '../../../shared/models/content_category.dart';
import '../../../shared/models/home_feed.dart';
import '../../../shared/models/video_item.dart';
import '../../../shared/repositories/home_repository.dart';

/// Demo home data. Clearly marked as mock — not live account data.
class MockHomeRepository implements HomeRepository {
  MockHomeRepository({
    this.simulateEmpty = false,
    this.simulateError = false,
    this.delay = const Duration(milliseconds: 350),
  });

  final bool simulateEmpty;
  final bool simulateError;
  final Duration delay;

  @override
  Future<HomeFeed> fetchHomeFeed({AudiencePreference? audienceOverride}) async {
    await Future<void>.delayed(delay);

    if (simulateError) {
      throw StateError('Mock home feed failed');
    }

    if (simulateEmpty) {
      return const HomeFeed(
        userDisplayName: 'Charlie',
        channels: [],
        recommended: [],
        exploreVideos: [],
        lastAudience: null,
        isMock: true,
      );
    }

    final audience = audienceOverride ?? AudiencePreference.kids;
    final isKids = audience == AudiencePreference.kids;

    // Channels come from ChannelRepository (user local data), not this mock.
    return HomeFeed(
      userDisplayName: 'Charlie',
      lastAudience: audience,
      isMock: true,
      channels: const [],
      recommended: _recommended(isKids: isKids),
      exploreVideos: _explore(isKids: isKids),
    );
  }

  List<VideoItem> _recommended({required bool isKids}) {
    if (isKids) {
      return const [
        VideoItem(
          id: 'rec_k1',
          title: '별자리 이야기',
          thumbnailColor: ColorSeed(0xFF5B4A8A),
          category: ContentCategory.science,
          isKidsAudience: true,
          youtuberName: 'Sky Lab',
          durationLabel: '8:12',
        ),
        VideoItem(
          id: 'rec_k2',
          title: '리듬으로 배우는 ABC',
          thumbnailColor: ColorSeed(0xFF4A7A6A),
          category: ContentCategory.english,
          isKidsAudience: true,
          youtuberName: 'Tune Kids',
          durationLabel: '5:40',
        ),
        VideoItem(
          id: 'rec_k3',
          title: '수채화로 행성 그리기',
          thumbnailColor: ColorSeed(0xFF8A5A4A),
          category: ContentCategory.art,
          isKidsAudience: true,
          youtuberName: 'Paint Orbit',
          durationLabel: '12:05',
        ),
        VideoItem(
          id: 'rec_k4',
          title: '바다 동물 친구들',
          thumbnailColor: ColorSeed(0xFF3A6A8A),
          category: ContentCategory.animals,
          isKidsAudience: true,
          youtuberName: 'Ocean Soft',
          durationLabel: '9:18',
        ),
      ];
    }

    return const [
      VideoItem(
        id: 'rec_g1',
        title: 'Flutter 반응형 레이아웃',
        thumbnailColor: ColorSeed(0xFF3D4A6A),
        category: ContentCategory.other,
        isKidsAudience: false,
        youtuberName: 'Code Violet',
        durationLabel: '18:22',
      ),
      VideoItem(
        id: 'rec_g2',
        title: '우주 다큐: 궤도 역학',
        thumbnailColor: ColorSeed(0xFF4A3A5A),
        category: ContentCategory.science,
        isKidsAudience: false,
        youtuberName: 'Orbit Desk',
        durationLabel: '24:10',
      ),
      VideoItem(
        id: 'rec_g3',
        title: '로파이 집중 플레이리스트',
        thumbnailColor: ColorSeed(0xFF2A3A4A),
        category: ContentCategory.music,
        isKidsAudience: false,
        youtuberName: 'Night Signal',
        durationLabel: '1:02:00',
      ),
    ];
  }

  List<VideoItem> _explore({required bool isKids}) {
    final base = <VideoItem>[
      const VideoItem(
        id: 'ex_1',
        title: 'Hello Song Warm-up',
        thumbnailColor: ColorSeed(0xFF5A6A4A),
        category: ContentCategory.english,
        isKidsAudience: true,
        channelId: 'ch_kids_music',
      ),
      const VideoItem(
        id: 'ex_2',
        title: '피아노로 듣는 달빛',
        thumbnailColor: ColorSeed(0xFF4A4A6A),
        category: ContentCategory.music,
        isKidsAudience: true,
        channelId: 'ch_kids_music',
      ),
      const VideoItem(
        id: 'ex_3',
        title: '로켓은 어떻게 날까?',
        thumbnailColor: ColorSeed(0xFF6A4A4A),
        category: ContentCategory.science,
        isKidsAudience: true,
        channelId: 'ch_kids_space',
      ),
      const VideoItem(
        id: 'ex_4',
        title: '색종이로 별 접기',
        thumbnailColor: ColorSeed(0xFF6A5A3A),
        category: ContentCategory.art,
        isKidsAudience: true,
        channelId: 'ch_kids_space',
      ),
      const VideoItem(
        id: 'ex_5',
        title: '고양이 관찰 일기',
        thumbnailColor: ColorSeed(0xFF4A5A5A),
        category: ContentCategory.animals,
        isKidsAudience: true,
        channelId: 'ch_kids_space',
      ),
      const VideoItem(
        id: 'ex_6',
        title: '채널 큐레이션 팁',
        thumbnailColor: ColorSeed(0xFF3A3A4A),
        category: ContentCategory.other,
        isKidsAudience: false,
        channelId: 'ch_general_dev',
      ),
      const VideoItem(
        id: 'ex_7',
        title: 'English Tech Briefing',
        thumbnailColor: ColorSeed(0xFF3A4A5A),
        category: ContentCategory.english,
        isKidsAudience: false,
        channelId: 'ch_general_dev',
      ),
      const VideoItem(
        id: 'ex_8',
        title: '합성기 사운드 디자인',
        thumbnailColor: ColorSeed(0xFF4A3A5A),
        category: ContentCategory.music,
        isKidsAudience: false,
        channelId: 'ch_general_dev',
      ),
    ];

    if (isKids) {
      return base.where((v) => v.isKidsAudience).toList();
    }
    return base.where((v) => !v.isKidsAudience).toList();
  }
}
