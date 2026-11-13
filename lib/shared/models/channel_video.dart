import 'content_enums.dart';

class ChannelVideo {
  const ChannelVideo({
    required this.youtubeVideoId,
    required this.tupicChannelId,
    required this.sourceIds,
    required this.title,
    required this.addedAt,
    required this.manualOrder,
    required this.metadataStatus,
    this.originalTitle,
    this.customTitle,
    this.thumbnailUrl,
    this.durationSeconds,
    this.isExcluded = false,
  });

  final String youtubeVideoId;
  final String tupicChannelId;
  final List<String> sourceIds;

  /// Legacy mirrored display title (kept in sync with [displayTitle] on write).
  final String title;

  /// YouTube snippet title when known.
  final String? originalTitle;

  /// Optional user override in TUPICK (null/blank → use original).
  final String? customTitle;

  final String? thumbnailUrl;
  final int? durationSeconds;
  final MetadataStatus metadataStatus;
  final DateTime addedAt;
  final int manualOrder;
  final bool isExcluded;

  /// Official YouTube thumbnail pattern (may 404; UI must fall back).
  static String defaultThumbnailUrl(String videoId) =>
      'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

  static String provisionalTitle(String videoId) => 'YouTube 영상 · $videoId';

  static String provisionalTitleEn(String videoId) => 'YouTube video · $videoId';

  static bool isProvisionalTitleText(String? title, String videoId) {
    if (title == null) return false;
    final t = title.trim();
    if (t.isEmpty) return true;
    return t == provisionalTitle(videoId) ||
        t == provisionalTitleEn(videoId) ||
        t == 'YouTube video · $videoId' ||
        t == 'YouTube 영상 · $videoId';
  }

  /// 1) customTitle 2) originalTitle 3) legacy non-empty title 4) provisional.
  String get displayTitle {
    final custom = customTitle?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final original = originalTitle?.trim();
    if (original != null && original.isNotEmpty) return original;
    final legacy = title.trim();
    if (legacy.isNotEmpty) return legacy;
    return provisionalTitle(youtubeVideoId);
  }

  bool get hasCustomTitle {
    final custom = customTitle?.trim();
    return custom != null && custom.isNotEmpty;
  }

  ChannelVideo copyWith({
    List<String>? sourceIds,
    String? title,
    String? originalTitle,
    String? customTitle,
    bool clearCustomTitle = false,
    bool clearOriginalTitle = false,
    String? thumbnailUrl,
    int? durationSeconds,
    MetadataStatus? metadataStatus,
    int? manualOrder,
    bool? isExcluded,
  }) {
    final next = ChannelVideo(
      youtubeVideoId: youtubeVideoId,
      tupicChannelId: tupicChannelId,
      sourceIds: sourceIds ?? this.sourceIds,
      title: title ?? this.title,
      originalTitle:
          clearOriginalTitle ? null : (originalTitle ?? this.originalTitle),
      customTitle: clearCustomTitle ? null : (customTitle ?? this.customTitle),
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      metadataStatus: metadataStatus ?? this.metadataStatus,
      addedAt: addedAt,
      manualOrder: manualOrder ?? this.manualOrder,
      isExcluded: isExcluded ?? this.isExcluded,
    );
    // Keep legacy `title` aligned with display rules unless caller forced it.
    if (title != null) return next;
    return ChannelVideo(
      youtubeVideoId: next.youtubeVideoId,
      tupicChannelId: next.tupicChannelId,
      sourceIds: next.sourceIds,
      title: next.displayTitle,
      originalTitle: next.originalTitle,
      customTitle: next.customTitle,
      thumbnailUrl: next.thumbnailUrl,
      durationSeconds: next.durationSeconds,
      metadataStatus: next.metadataStatus,
      addedAt: next.addedAt,
      manualOrder: next.manualOrder,
      isExcluded: next.isExcluded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'youtubeVideoId': youtubeVideoId,
      'tupicChannelId': tupicChannelId,
      'sourceIds': sourceIds,
      'title': displayTitle,
      if (originalTitle != null) 'originalTitle': originalTitle,
      if (customTitle != null) 'customTitle': customTitle,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': durationSeconds,
      'metadataStatus': metadataStatus.storageValue,
      'addedAt': addedAt.toIso8601String(),
      'manualOrder': manualOrder,
      'isExcluded': isExcluded,
    };
  }

  static ChannelVideo? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      final videoId = json['youtubeVideoId'];
      final channelId = json['tupicChannelId'];
      final title = json['title'];
      if (videoId is! String || channelId is! String || title is! String) {
        return null;
      }
      final sourceRaw = json['sourceIds'];
      final sourceIds = sourceRaw is List
          ? sourceRaw.whereType<String>().toList(growable: false)
          : const <String>[];
      final addedRaw = json['addedAt'];
      final addedAt = addedRaw is String
          ? DateTime.tryParse(addedRaw) ?? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0);

      String? asOptString(dynamic value) {
        if (value is! String) return null;
        final trimmed = value.trim();
        return trimmed.isEmpty ? null : trimmed;
      }

      var originalTitle = asOptString(json['originalTitle']);
      var customTitle = asOptString(json['customTitle']);

      // Legacy rows: only `title` exists. Do not invent custom titles.
      if (originalTitle == null && customTitle == null) {
        if (!isProvisionalTitleText(title, videoId)) {
          originalTitle = title.trim();
        }
      }

      final video = ChannelVideo(
        youtubeVideoId: videoId,
        tupicChannelId: channelId,
        sourceIds: sourceIds,
        title: title,
        originalTitle: originalTitle,
        customTitle: customTitle,
        thumbnailUrl: json['thumbnailUrl'] is String
            ? json['thumbnailUrl'] as String
            : null,
        durationSeconds: json['durationSeconds'] is int
            ? json['durationSeconds'] as int
            : null,
        metadataStatus: MetadataStatusX.fromStorage(
          json['metadataStatus'] is String
              ? json['metadataStatus'] as String
              : null,
        ),
        addedAt: addedAt,
        manualOrder: json['manualOrder'] is int ? json['manualOrder'] as int : 0,
        isExcluded: json['isExcluded'] == true,
      );
      return video.copyWith(title: video.displayTitle);
    } catch (_) {
      return null;
    }
  }
}
