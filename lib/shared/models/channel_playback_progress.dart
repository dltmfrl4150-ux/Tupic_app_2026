import 'play_order.dart';

/// Per-channel resume checkpoint for STEP 3B playback.
class ChannelPlaybackProgress {
  const ChannelPlaybackProgress({
    required this.tupicChannelId,
    required this.youtubeVideoId,
    required this.positionSeconds,
    required this.updatedAt,
    this.sessionQueueIds,
    this.sessionPlayOrder,
  });

  final String tupicChannelId;
  final String youtubeVideoId;
  final double positionSeconds;
  final DateTime updatedAt;

  /// Optional shuffle-session order (YouTube video IDs).
  final List<String>? sessionQueueIds;
  final PlayOrder? sessionPlayOrder;

  ChannelPlaybackProgress copyWith({
    String? youtubeVideoId,
    double? positionSeconds,
    DateTime? updatedAt,
    List<String>? sessionQueueIds,
    PlayOrder? sessionPlayOrder,
  }) {
    return ChannelPlaybackProgress(
      tupicChannelId: tupicChannelId,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      updatedAt: updatedAt ?? this.updatedAt,
      sessionQueueIds: sessionQueueIds ?? this.sessionQueueIds,
      sessionPlayOrder: sessionPlayOrder ?? this.sessionPlayOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tupicChannelId': tupicChannelId,
      'youtubeVideoId': youtubeVideoId,
      'positionSeconds': positionSeconds,
      'updatedAt': updatedAt.toIso8601String(),
      if (sessionQueueIds != null) 'sessionQueueIds': sessionQueueIds,
      if (sessionPlayOrder != null)
        'sessionPlayOrder': sessionPlayOrder!.storageValue,
    };
  }

  static ChannelPlaybackProgress? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      final channelId = json['tupicChannelId'];
      final videoId = json['youtubeVideoId'];
      if (channelId is! String || videoId is! String) return null;
      final positionRaw = json['positionSeconds'];
      final position = positionRaw is num ? positionRaw.toDouble() : 0.0;
      final updatedRaw = json['updatedAt'];
      final updatedAt = updatedRaw is String
          ? DateTime.tryParse(updatedRaw) ??
                DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0);
      final queueRaw = json['sessionQueueIds'];
      final queueIds = queueRaw is List
          ? queueRaw.whereType<String>().toList(growable: false)
          : null;
      final orderRaw = json['sessionPlayOrder'];
      return ChannelPlaybackProgress(
        tupicChannelId: channelId,
        youtubeVideoId: videoId,
        positionSeconds: position.isFinite ? position : 0,
        updatedAt: updatedAt,
        sessionQueueIds: queueIds,
        sessionPlayOrder: orderRaw is String
            ? PlayOrderX.fromStorage(orderRaw)
            : null,
      );
    } catch (_) {
      return null;
    }
  }
}
