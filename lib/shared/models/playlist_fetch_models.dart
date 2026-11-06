/// A single playlist item returned by the local YouTube API proxy.
class PlaylistVideoItem {
  const PlaylistVideoItem({
    required this.youtubeVideoId,
    required this.title,
    required this.position,
    this.thumbnailUrl,
    this.publishedAt,
    this.playlistId,
  });

  final String youtubeVideoId;
  final String title;
  final int position;
  final String? thumbnailUrl;
  final DateTime? publishedAt;
  final String? playlistId;

  factory PlaylistVideoItem.fromJson(Map<String, dynamic> json) {
    final id = json['youtubeVideoId'] ?? json['videoId'];
    if (id is! String || id.isEmpty) {
      throw FormatException('Missing youtubeVideoId');
    }
    final title = json['title'];
    final position = json['position'];
    return PlaylistVideoItem(
      youtubeVideoId: id,
      title: title is String && title.isNotEmpty ? title : 'YouTube video · $id',
      position: position is int
          ? position
          : (position is num ? position.toInt() : 0),
      thumbnailUrl: json['thumbnailUrl'] is String
          ? json['thumbnailUrl'] as String
          : null,
      publishedAt: json['publishedAt'] is String
          ? DateTime.tryParse(json['publishedAt'] as String)
          : null,
      playlistId: json['playlistId'] is String
          ? json['playlistId'] as String
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'youtubeVideoId': youtubeVideoId,
    'title': title,
    'position': position,
    'thumbnailUrl': thumbnailUrl,
    'publishedAt': publishedAt?.toIso8601String(),
    'playlistId': playlistId,
  };
}

class PlaylistFetchResult {
  const PlaylistFetchResult({
    required this.playlistId,
    required this.videos,
    required this.hasMore,
    required this.truncatedByLimit,
    required this.skippedInvalid,
    this.excludedPrivateDeleted = 0,
    this.excludedNotEmbeddable = 0,
    this.excludedMissing = 0,
    this.excludedVideoIds = const [],
    this.fromCache = false,
  });

  final String playlistId;
  final List<PlaylistVideoItem> videos;
  final bool hasMore;
  final bool truncatedByLimit;
  final int skippedInvalid;
  final int excludedPrivateDeleted;
  final int excludedNotEmbeddable;
  final int excludedMissing;
  final List<String> excludedVideoIds;
  final bool fromCache;

  int get excludedUnplayableTotal =>
      excludedPrivateDeleted + excludedNotEmbeddable + excludedMissing;

  factory PlaylistFetchResult.fromJson(Map<String, dynamic> json) {
    final playlistId = json['playlistId'];
    if (playlistId is! String) {
      throw FormatException('Missing playlistId');
    }
    final raw = json['videos'];
    final videos = <PlaylistVideoItem>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          try {
            videos.add(
              PlaylistVideoItem.fromJson(Map<String, dynamic>.from(item)),
            );
          } catch (_) {
            // Skip malformed rows.
          }
        }
      }
    }
    int asInt(dynamic value) => value is int
        ? value
        : (value is num ? value.toInt() : 0);
    final excludedRaw = json['excludedVideoIds'];
    final excludedVideoIds = excludedRaw is List
        ? excludedRaw.whereType<String>().toList(growable: false)
        : const <String>[];

    return PlaylistFetchResult(
      playlistId: playlistId,
      videos: videos,
      hasMore: json['hasMore'] == true,
      truncatedByLimit: json['truncatedByLimit'] == true,
      skippedInvalid: asInt(json['skippedInvalid']),
      excludedPrivateDeleted: asInt(json['excludedPrivateDeleted']),
      excludedNotEmbeddable: asInt(json['excludedNotEmbeddable']),
      excludedMissing: asInt(json['excludedMissing']),
      excludedVideoIds: excludedVideoIds,
      fromCache: json['fromCache'] == true,
    );
  }
}

class VideoValidationResult {
  const VideoValidationResult({
    required this.playableIds,
    required this.unplayableIds,
    this.excludedPrivateDeleted = 0,
    this.excludedNotEmbeddable = 0,
    this.excludedMissing = 0,
  });

  final List<String> playableIds;
  final List<String> unplayableIds;
  final int excludedPrivateDeleted;
  final int excludedNotEmbeddable;
  final int excludedMissing;

  factory VideoValidationResult.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) => value is int
        ? value
        : (value is num ? value.toInt() : 0);
    List<String> asIds(dynamic raw) => raw is List
        ? raw.whereType<String>().toList(growable: false)
        : const <String>[];
    return VideoValidationResult(
      playableIds: asIds(json['playableIds']),
      unplayableIds: asIds(json['unplayableIds']),
      excludedPrivateDeleted: asInt(json['excludedPrivateDeleted']),
      excludedNotEmbeddable: asInt(json['excludedNotEmbeddable']),
      excludedMissing: asInt(json['excludedMissing']),
    );
  }
}

class PlaylistImportReport {
  const PlaylistImportReport({
    required this.sourceId,
    required this.importedCount,
    required this.duplicateCount,
    required this.skippedInvalidCount,
    required this.omittedByLimitCount,
    required this.truncatedByLimit,
    required this.hasMoreOnYoutube,
    required this.totalLinkedToSource,
    this.excludedPrivateDeleted = 0,
    this.excludedNotEmbeddable = 0,
    this.excludedMissing = 0,
    this.prunedUnplayableCount = 0,
  });

  final String sourceId;
  final int importedCount;
  final int duplicateCount;
  final int skippedInvalidCount;
  final int omittedByLimitCount;
  final bool truncatedByLimit;
  final bool hasMoreOnYoutube;
  final int totalLinkedToSource;
  final int excludedPrivateDeleted;
  final int excludedNotEmbeddable;
  final int excludedMissing;
  final int prunedUnplayableCount;
}

/// Defensive check for playlist placeholder titles (not a sole playability proof).
bool isPlaceholderVideoTitle(String? title) {
  if (title == null) return false;
  final t = title.trim().toLowerCase();
  return t == 'private video' || t == 'deleted video';
}

class YoutubeApiException implements Exception {
  const YoutubeApiException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  bool get isMissingApiKey => code == 'missing_api_key';
  bool get isQuotaExceeded => code == 'quota_exceeded';
  bool get isConnectionFailed =>
      code == 'connection_failed' || code == 'timeout';
  bool get isDailyLimit => code == 'daily_limit';

  @override
  String toString() => 'YoutubeApiException($code)';
}
