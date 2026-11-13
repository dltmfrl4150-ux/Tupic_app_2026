import 'shared_channel_category.dart';

enum SharePostStatus {
  published,
  cancelled;

  String get storageValue => name;

  static SharePostStatus fromStorage(String? value) {
    return switch (value) {
      'cancelled' => SharePostStatus.cancelled,
      _ => SharePostStatus.published,
    };
  }
}

/// Share history group for one local channel owned by one user.
class ShareGroup {
  const ShareGroup({
    required this.id,
    required this.ownerUid,
    required this.sourceChannelId,
    required this.latestVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String sourceChannelId;
  final int latestVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  static String documentId({
    required String ownerUid,
    required String sourceChannelId,
  }) =>
      '${ownerUid}__$sourceChannelId';
}

/// One immutable published version of a shared channel.
class SharePost {
  const SharePost({
    required this.id,
    required this.groupId,
    required this.ownerUid,
    required this.version,
    required this.title,
    required this.category,
    required this.isKids,
    required this.videoCount,
    required this.snapshot,
    required this.createdAt,
    required this.status,
    this.description,
    this.cancelledAt,
  });

  final String id;
  final String groupId;
  final String ownerUid;
  final int version;
  final String title;
  final String? description;
  final SharedChannelCategory category;
  final bool isKids;
  final int videoCount;
  final ShareSnapshot snapshot;
  final DateTime createdAt;
  final SharePostStatus status;
  final DateTime? cancelledAt;

  bool get isPublished => status == SharePostStatus.published;
}

class ShareSnapshot {
  const ShareSnapshot({
    required this.channelName,
    required this.isKidsChannel,
    required this.playOrder,
    required this.videos,
    this.coverLabel,
    this.accentColor,
  });

  final String channelName;
  final bool isKidsChannel;
  final String playOrder;
  final String? coverLabel;
  final int? accentColor;
  final List<ShareSnapshotVideo> videos;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'channelName': channelName,
      'isKidsChannel': isKidsChannel,
      'playOrder': playOrder,
      if (coverLabel != null) 'coverLabel': coverLabel,
      if (accentColor != null) 'accentColor': accentColor,
      'videos': videos.map((v) => v.toFirestoreMap()).toList(growable: false),
    };
  }

  static ShareSnapshot? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final name = data['channelName'];
    final playOrder = data['playOrder'];
    final videosRaw = data['videos'];
    if (name is! String || playOrder is! String || videosRaw is! List) {
      return null;
    }
    final videos = <ShareSnapshotVideo>[];
    for (final item in videosRaw) {
      if (item is! Map) continue;
      final video = ShareSnapshotVideo.fromMap(
        Map<String, dynamic>.from(item),
      );
      if (video != null) videos.add(video);
    }
    return ShareSnapshot(
      channelName: name,
      isKidsChannel: data['isKidsChannel'] == true,
      playOrder: playOrder,
      coverLabel: data['coverLabel'] is String ? data['coverLabel'] as String : null,
      accentColor: data['accentColor'] is int ? data['accentColor'] as int : null,
      videos: videos,
    );
  }
}

class ShareSnapshotVideo {
  const ShareSnapshotVideo({
    required this.youtubeVideoId,
    required this.title,
    required this.manualOrder,
    this.originalTitle,
    this.customTitle,
    this.thumbnailUrl,
    this.durationSeconds,
  });

  final String youtubeVideoId;
  final String title;
  final String? originalTitle;
  final String? customTitle;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final int manualOrder;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'youtubeVideoId': youtubeVideoId,
      'title': title,
      if (originalTitle != null) 'originalTitle': originalTitle,
      if (customTitle != null) 'customTitle': customTitle,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      'manualOrder': manualOrder,
    };
  }

  static ShareSnapshotVideo? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final id = data['youtubeVideoId'];
    final title = data['title'];
    if (id is! String || title is! String) return null;
    return ShareSnapshotVideo(
      youtubeVideoId: id,
      title: title,
      originalTitle:
          data['originalTitle'] is String ? data['originalTitle'] as String : null,
      customTitle:
          data['customTitle'] is String ? data['customTitle'] as String : null,
      thumbnailUrl:
          data['thumbnailUrl'] is String ? data['thumbnailUrl'] as String : null,
      durationSeconds: data['durationSeconds'] is int
          ? data['durationSeconds'] as int
          : null,
      manualOrder: data['manualOrder'] is int ? data['manualOrder'] as int : 0,
    );
  }
}
