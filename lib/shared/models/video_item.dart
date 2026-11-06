import 'content_category.dart';

/// A curated YouTube video referenced by TUPIC (not an ad).
class VideoItem {
  const VideoItem({
    required this.id,
    required this.title,
    required this.thumbnailColor,
    required this.category,
    required this.isKidsAudience,
    this.channelId,
    this.youtuberName,
    this.durationLabel,
  });

  final String id;
  final String title;
  final ColorSeed thumbnailColor;
  final ContentCategory category;
  final bool isKidsAudience;
  final String? channelId;
  final String? youtuberName;
  final String? durationLabel;
}

/// Lightweight color seed for mock thumbnails (no external image URLs).
class ColorSeed {
  const ColorSeed(this.value);

  final int value;
}
