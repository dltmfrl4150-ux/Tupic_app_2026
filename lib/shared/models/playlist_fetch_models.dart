/// A single playlist item returned by the local YouTube API proxy.
class PlaylistVideoItem {
  const PlaylistVideoItem({
    required this.youtubeVideoId,
    required this.title,
    required this.position,
    this.thumbnailUrl,
    this.publishedAt,
    this.playlistId,
    this.channelTitle,
  });

  final String youtubeVideoId;
  final String title;
  final int position;
  final String? thumbnailUrl;
  final DateTime? publishedAt;
  final String? playlistId;
  final String? channelTitle;

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
      channelTitle: json['channelTitle'] is String
          ? json['channelTitle'] as String
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
    'channelTitle': channelTitle,
  };
}

/// Resolved YouTube channel (uploads playlist) from the local proxy.
class ResolvedYoutubeChannel {
  const ResolvedYoutubeChannel({
    required this.channelId,
    required this.title,
    required this.uploadsPlaylistId,
    this.thumbnailUrl,
    this.customUrl,
  });

  final String channelId;
  final String title;
  final String uploadsPlaylistId;
  final String? thumbnailUrl;
  final String? customUrl;

  factory ResolvedYoutubeChannel.fromJson(Map<String, dynamic> json) {
    final channelId = json['channelId'];
    final title = json['title'];
    final uploads = json['uploadsPlaylistId'];
    if (channelId is! String ||
        title is! String ||
        uploads is! String ||
        channelId.isEmpty ||
        uploads.isEmpty) {
      throw const FormatException('Invalid channel resolve payload');
    }
    return ResolvedYoutubeChannel(
      channelId: channelId,
      title: title,
      uploadsPlaylistId: uploads,
      thumbnailUrl: json['thumbnailUrl'] is String
          ? json['thumbnailUrl'] as String
          : null,
      customUrl: json['customUrl'] is String ? json['customUrl'] as String : null,
    );
  }
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
    this.excludedAgeRestricted = 0,
    this.excludedVerificationFailed = 0,
    this.excludedVideoIds = const [],
    this.ageRestrictedVideos = const [],
    this.ageRestrictedIds = const [],
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
  final int excludedAgeRestricted;
  final int excludedVerificationFailed;
  final List<String> excludedVideoIds;
  /// Age-restricted items classified by the proxy (not in [videos]).
  final List<PlaylistVideoItem> ageRestrictedVideos;
  final List<String> ageRestrictedIds;
  final bool fromCache;

  int get excludedUnplayableTotal =>
      excludedPrivateDeleted +
      excludedNotEmbeddable +
      excludedMissing +
      excludedAgeRestricted +
      excludedVerificationFailed;

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
    final ageRestrictedVideos = <PlaylistVideoItem>[];
    final ageRaw = json['ageRestrictedVideos'];
    if (ageRaw is List) {
      for (final item in ageRaw) {
        if (item is Map) {
          try {
            ageRestrictedVideos.add(
              PlaylistVideoItem.fromJson(Map<String, dynamic>.from(item)),
            );
          } catch (_) {}
        }
      }
    }
    final ageIdsRaw = json['ageRestrictedIds'];
    final ageRestrictedIds = ageIdsRaw is List
        ? ageIdsRaw.whereType<String>().toList(growable: false)
        : ageRestrictedVideos
            .map((v) => v.youtubeVideoId)
            .toList(growable: false);

    return PlaylistFetchResult(
      playlistId: playlistId,
      videos: videos,
      hasMore: json['hasMore'] == true,
      truncatedByLimit: json['truncatedByLimit'] == true,
      skippedInvalid: asInt(json['skippedInvalid']),
      excludedPrivateDeleted: asInt(json['excludedPrivateDeleted']),
      excludedNotEmbeddable: asInt(json['excludedNotEmbeddable']),
      excludedMissing: asInt(json['excludedMissing']),
      excludedAgeRestricted: asInt(json['excludedAgeRestricted']),
      excludedVerificationFailed: asInt(json['excludedVerificationFailed']),
      excludedVideoIds: excludedVideoIds,
      ageRestrictedVideos: ageRestrictedVideos,
      ageRestrictedIds: ageRestrictedIds,
      fromCache: json['fromCache'] == true,
    );
  }
}

class VideoValidationResult {
  const VideoValidationResult({
    required this.playableIds,
    required this.unplayableIds,
    this.playableVideos = const [],
    this.ageRestrictedIds = const [],
    this.ageRestrictedVideos = const [],
    this.verificationFailedIds = const [],
    this.excludedPrivateDeleted = 0,
    this.excludedNotEmbeddable = 0,
    this.excludedMissing = 0,
    this.excludedAgeRestricted = 0,
    this.excludedVerificationFailed = 0,
  });

  final List<String> playableIds;
  final List<String> unplayableIds;
  /// Titles/thumbnails from the same videos.list call (no extra quota).
  final List<PlaylistVideoItem> playableVideos;
  final List<String> ageRestrictedIds;
  final List<PlaylistVideoItem> ageRestrictedVideos;
  final List<String> verificationFailedIds;
  final int excludedPrivateDeleted;
  final int excludedNotEmbeddable;
  final int excludedMissing;
  final int excludedAgeRestricted;
  final int excludedVerificationFailed;

  PlaylistVideoItem? metaFor(String youtubeVideoId) {
    for (final item in playableVideos) {
      if (item.youtubeVideoId == youtubeVideoId) return item;
    }
    for (final item in ageRestrictedVideos) {
      if (item.youtubeVideoId == youtubeVideoId) return item;
    }
    return null;
  }

  factory VideoValidationResult.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) => value is int
        ? value
        : (value is num ? value.toInt() : 0);
    List<String> asIds(dynamic raw) => raw is List
        ? raw.whereType<String>().toList(growable: false)
        : const <String>[];
    List<PlaylistVideoItem> asVideos(dynamic raw) {
      if (raw is! List) return const [];
      final out = <PlaylistVideoItem>[];
      for (final item in raw) {
        if (item is Map) {
          try {
            out.add(PlaylistVideoItem.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
      return out;
    }

    return VideoValidationResult(
      playableIds: asIds(json['playableIds']),
      unplayableIds: asIds(json['unplayableIds']),
      playableVideos: asVideos(json['playableVideos']),
      ageRestrictedIds: asIds(json['ageRestrictedIds']),
      ageRestrictedVideos: asVideos(json['ageRestrictedVideos']),
      verificationFailedIds: asIds(json['verificationFailedIds']),
      excludedPrivateDeleted: asInt(json['excludedPrivateDeleted']),
      excludedNotEmbeddable: asInt(json['excludedNotEmbeddable']),
      excludedMissing: asInt(json['excludedMissing']),
      excludedAgeRestricted: asInt(json['excludedAgeRestricted']),
      excludedVerificationFailed: asInt(json['excludedVerificationFailed']),
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
    this.excludedAgeRestricted = 0,
    this.excludedVerificationFailed = 0,
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
  final int excludedAgeRestricted;
  final int excludedVerificationFailed;
  final int prunedUnplayableCount;
}

/// Single-video registration rejected because YouTube marks it age-restricted.
class AgeRestrictedVideoException implements Exception {
  const AgeRestrictedVideoException([this.youtubeVideoId]);
  final String? youtubeVideoId;

  @override
  String toString() => 'AgeRestrictedVideoException($youtubeVideoId)';
}

/// Single-video registration rejected because playability could not be verified.
class VideoVerificationFailedException implements Exception {
  const VideoVerificationFailedException([this.youtubeVideoId]);
  final String? youtubeVideoId;

  @override
  String toString() => 'VideoVerificationFailedException($youtubeVideoId)';
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
