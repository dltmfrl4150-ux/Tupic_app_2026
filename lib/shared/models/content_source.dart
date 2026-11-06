import 'content_enums.dart';

class ContentSource {
  const ContentSource({
    required this.id,
    required this.tupicChannelId,
    required this.sourceType,
    required this.originalUrl,
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
    required this.importStatus,
    this.youtubeVideoId,
    this.youtubePlaylistId,
    this.youtubeChannelId,
    this.youtubeHandle,
    this.youtubeUsername,
    this.youtubeCustomName,
    this.creatorImportMode = CreatorImportMode.recent30,
    this.creatorSortOrder = CreatorSortOrder.newest,
    this.autoSyncEnabled = false,
    this.excludedVideoIds = const [],
    this.manuallySelectedVideoIds = const [],
    this.lastFetchedAt,
    this.fetchedVideoCount = 0,
    this.lastErrorMessage,
  });

  final String id;
  final String tupicChannelId;
  final ContentSourceType sourceType;
  final String originalUrl;
  final String? youtubeVideoId;
  final String? youtubePlaylistId;
  final String? youtubeChannelId;
  final String? youtubeHandle;
  final String? youtubeUsername;
  final String? youtubeCustomName;
  final String displayName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ImportStatus importStatus;
  final CreatorImportMode creatorImportMode;
  final CreatorSortOrder creatorSortOrder;
  final bool autoSyncEnabled;
  final List<String> excludedVideoIds;
  final List<String> manuallySelectedVideoIds;
  final DateTime? lastFetchedAt;
  final int fetchedVideoCount;
  final String? lastErrorMessage;

  ContentSource copyWith({
    String? displayName,
    DateTime? updatedAt,
    ImportStatus? importStatus,
    CreatorImportMode? creatorImportMode,
    CreatorSortOrder? creatorSortOrder,
    bool? autoSyncEnabled,
    List<String>? excludedVideoIds,
    List<String>? manuallySelectedVideoIds,
    DateTime? lastFetchedAt,
    int? fetchedVideoCount,
    String? lastErrorMessage,
    bool clearLastError = false,
  }) {
    return ContentSource(
      id: id,
      tupicChannelId: tupicChannelId,
      sourceType: sourceType,
      originalUrl: originalUrl,
      youtubeVideoId: youtubeVideoId,
      youtubePlaylistId: youtubePlaylistId,
      youtubeChannelId: youtubeChannelId,
      youtubeHandle: youtubeHandle,
      youtubeUsername: youtubeUsername,
      youtubeCustomName: youtubeCustomName,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      importStatus: importStatus ?? this.importStatus,
      creatorImportMode: creatorImportMode ?? this.creatorImportMode,
      creatorSortOrder: creatorSortOrder ?? this.creatorSortOrder,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      excludedVideoIds: excludedVideoIds ?? this.excludedVideoIds,
      manuallySelectedVideoIds:
          manuallySelectedVideoIds ?? this.manuallySelectedVideoIds,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      fetchedVideoCount: fetchedVideoCount ?? this.fetchedVideoCount,
      lastErrorMessage: clearLastError
          ? null
          : (lastErrorMessage ?? this.lastErrorMessage),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tupicChannelId': tupicChannelId,
      'sourceType': sourceType.storageValue,
      'originalUrl': originalUrl,
      'youtubeVideoId': youtubeVideoId,
      'youtubePlaylistId': youtubePlaylistId,
      'youtubeChannelId': youtubeChannelId,
      'youtubeHandle': youtubeHandle,
      'youtubeUsername': youtubeUsername,
      'youtubeCustomName': youtubeCustomName,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'importStatus': importStatus.storageValue,
      'creatorImportMode': creatorImportMode.storageValue,
      'creatorSortOrder': creatorSortOrder.storageValue,
      'autoSyncEnabled': autoSyncEnabled,
      'excludedVideoIds': excludedVideoIds,
      'manuallySelectedVideoIds': manuallySelectedVideoIds,
      'lastFetchedAt': lastFetchedAt?.toIso8601String(),
      'fetchedVideoCount': fetchedVideoCount,
      'lastErrorMessage': lastErrorMessage,
    };
  }

  static ContentSource? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      final id = json['id'];
      final channelId = json['tupicChannelId'];
      final type = ContentSourceTypeX.fromStorage(
        json['sourceType'] is String ? json['sourceType'] as String : null,
      );
      final url = json['originalUrl'];
      final name = json['displayName'];
      if (id is! String ||
          channelId is! String ||
          type == null ||
          url is! String ||
          name is! String) {
        return null;
      }
      DateTime parseTime(dynamic raw) {
        if (raw is String) {
          return DateTime.tryParse(raw) ??
              DateTime.fromMillisecondsSinceEpoch(0);
        }
        return DateTime.fromMillisecondsSinceEpoch(0);
      }

      List<String> parseIds(dynamic raw) {
        if (raw is! List) return const [];
        return raw.whereType<String>().toList(growable: false);
      }

      return ContentSource(
        id: id,
        tupicChannelId: channelId,
        sourceType: type,
        originalUrl: url,
        youtubeVideoId: json['youtubeVideoId'] is String
            ? json['youtubeVideoId'] as String
            : null,
        youtubePlaylistId: json['youtubePlaylistId'] is String
            ? json['youtubePlaylistId'] as String
            : null,
        youtubeChannelId: json['youtubeChannelId'] is String
            ? json['youtubeChannelId'] as String
            : null,
        youtubeHandle: json['youtubeHandle'] is String
            ? json['youtubeHandle'] as String
            : null,
        youtubeUsername: json['youtubeUsername'] is String
            ? json['youtubeUsername'] as String
            : null,
        youtubeCustomName: json['youtubeCustomName'] is String
            ? json['youtubeCustomName'] as String
            : null,
        displayName: name,
        createdAt: parseTime(json['createdAt']),
        updatedAt: parseTime(json['updatedAt']),
        importStatus: ImportStatusX.fromStorage(
          json['importStatus'] is String ? json['importStatus'] as String : null,
        ),
        creatorImportMode: CreatorImportModeX.fromStorage(
          json['creatorImportMode'] is String
              ? json['creatorImportMode'] as String
              : null,
        ),
        creatorSortOrder: CreatorSortOrderX.fromStorage(
          json['creatorSortOrder'] is String
              ? json['creatorSortOrder'] as String
              : null,
        ),
        autoSyncEnabled: json['autoSyncEnabled'] == true,
        excludedVideoIds: parseIds(json['excludedVideoIds']),
        manuallySelectedVideoIds: parseIds(json['manuallySelectedVideoIds']),
        lastFetchedAt: json['lastFetchedAt'] is String
            ? DateTime.tryParse(json['lastFetchedAt'] as String)
            : null,
        fetchedVideoCount: json['fetchedVideoCount'] is int
            ? json['fetchedVideoCount'] as int
            : 0,
        lastErrorMessage: json['lastErrorMessage'] is String
            ? json['lastErrorMessage'] as String
            : null,
      );
    } catch (_) {
      return null;
    }
  }
}
