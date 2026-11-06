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
    this.thumbnailUrl,
    this.durationSeconds,
    this.isExcluded = false,
  });

  final String youtubeVideoId;
  final String tupicChannelId;
  final List<String> sourceIds;
  final String title;
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

  ChannelVideo copyWith({
    List<String>? sourceIds,
    String? title,
    String? thumbnailUrl,
    int? durationSeconds,
    MetadataStatus? metadataStatus,
    int? manualOrder,
    bool? isExcluded,
  }) {
    return ChannelVideo(
      youtubeVideoId: youtubeVideoId,
      tupicChannelId: tupicChannelId,
      sourceIds: sourceIds ?? this.sourceIds,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      metadataStatus: metadataStatus ?? this.metadataStatus,
      addedAt: addedAt,
      manualOrder: manualOrder ?? this.manualOrder,
      isExcluded: isExcluded ?? this.isExcluded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'youtubeVideoId': youtubeVideoId,
      'tupicChannelId': tupicChannelId,
      'sourceIds': sourceIds,
      'title': title,
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
      return ChannelVideo(
        youtubeVideoId: videoId,
        tupicChannelId: channelId,
        sourceIds: sourceIds,
        title: title,
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
    } catch (_) {
      return null;
    }
  }
}
