import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/plan_limits.dart';
import '../../../shared/models/channel_video.dart';
import '../../../shared/models/content_enums.dart';
import '../../../shared/models/content_source.dart';
import '../../../shared/models/playlist_fetch_models.dart';
import '../../../shared/repositories/content_repository.dart';

const sourcesKey = 'tupic_content_sources_v1';
const videosKey = 'tupic_channel_videos_v1';
const sourcesBackupKey = 'tupic_content_sources_v1_backup';
const videosBackupKey = 'tupic_channel_videos_v1_backup';

class LocalContentRepository implements ContentRepository {
  LocalContentRepository({
    SharedPreferences? prefs,
    this.maxVideosPerChannel = PlanLimits.freeMaxVideosPerChannel,
    this.isPremium = PlanLimits.isPremium,
    Random? random,
  }) : _prefsOverride = prefs,
       _random = random ?? Random();

  final SharedPreferences? _prefsOverride;
  final int maxVideosPerChannel;
  final bool isPremium;
  final Random _random;
  SharedPreferences? _cachedPrefs;

  /// When true, last load failed and empty data must not overwrite storage.
  bool _sourcesCorrupt = false;
  bool _videosCorrupt = false;

  Future<SharedPreferences> _prefs() async {
    return _cachedPrefs ??=
        _prefsOverride ?? await SharedPreferences.getInstance();
  }

  @override
  Future<List<ContentSource>> getSources({String? tupicChannelId}) async {
    final all = await _loadSources();
    if (tupicChannelId == null) return all;
    return all.where((s) => s.tupicChannelId == tupicChannelId).toList();
  }

  @override
  Future<List<ChannelVideo>> getVideos({String? tupicChannelId}) async {
    final all = await _loadVideos();
    final filtered = tupicChannelId == null
        ? all
        : all.where((v) => v.tupicChannelId == tupicChannelId).toList();
    filtered.sort((a, b) => a.manualOrder.compareTo(b.manualOrder));
    return filtered;
  }

  @override
  Future<int> countActiveVideos(String tupicChannelId) async {
    final videos = await getVideos(tupicChannelId: tupicChannelId);
    return videos.where((v) => !v.isExcluded).length;
  }

  @override
  Future<ContentSource> addVideoSource({
    required String tupicChannelId,
    required String originalUrl,
    required String youtubeVideoId,
    required String displayName,
  }) async {
    final videos = await _loadVideos();
    final channelVideos =
        videos.where((v) => v.tupicChannelId == tupicChannelId).toList();
    final existing = channelVideos
        .where((v) => v.youtubeVideoId == youtubeVideoId)
        .toList();
    if (existing.isNotEmpty) {
      throw DuplicateVideoException(youtubeVideoId);
    }

    final activeCount = channelVideos.where((v) => !v.isExcluded).length;
    if (activeCount >= maxVideosPerChannel) {
      throw VideoLimitExceededException(maxVideosPerChannel);
    }

    final now = DateTime.now();
    final sourceId =
        'src_${now.microsecondsSinceEpoch}_${_random.nextInt(9999)}';
    final source = ContentSource(
      id: sourceId,
      tupicChannelId: tupicChannelId,
      sourceType: ContentSourceType.video,
      originalUrl: originalUrl,
      youtubeVideoId: youtubeVideoId,
      displayName: displayName.trim().isEmpty
          ? ChannelVideo.provisionalTitle(youtubeVideoId)
          : displayName.trim(),
      createdAt: now,
      updatedAt: now,
      importStatus: ImportStatus.ready,
    );

    final nextOrder = channelVideos.isEmpty
        ? 0
        : channelVideos
                  .map((v) => v.manualOrder)
                  .reduce((a, b) => a > b ? a : b) +
              1;

    final video = ChannelVideo(
      youtubeVideoId: youtubeVideoId,
      tupicChannelId: tupicChannelId,
      sourceIds: [sourceId],
      title: source.displayName,
      thumbnailUrl: ChannelVideo.defaultThumbnailUrl(youtubeVideoId),
      metadataStatus: MetadataStatus.unresolved,
      addedAt: now,
      manualOrder: nextOrder,
    );

    final sources = await _loadSources();
    await _saveSources([...sources, source]);
    await _saveVideos([...videos, video]);
    return source;
  }

  @override
  Future<ContentSource> addPlaylistSource({
    required String tupicChannelId,
    required String originalUrl,
    required String youtubePlaylistId,
    required String displayName,
  }) async {
    final now = DateTime.now();
    final source = ContentSource(
      id: 'src_${now.microsecondsSinceEpoch}_${_random.nextInt(9999)}',
      tupicChannelId: tupicChannelId,
      sourceType: ContentSourceType.playlist,
      originalUrl: originalUrl,
      youtubePlaylistId: youtubePlaylistId,
      displayName: displayName.trim().isEmpty
          ? 'YouTube playlist · $youtubePlaylistId'
          : displayName.trim(),
      createdAt: now,
      updatedAt: now,
      importStatus: ImportStatus.pendingFetch,
    );
    final sources = await _loadSources();
    await _saveSources([...sources, source]);
    return source;
  }

  @override
  Future<ContentSource> addCreatorSource({
    required String tupicChannelId,
    required String originalUrl,
    required String displayName,
    String? youtubeChannelId,
    String? youtubeHandle,
    String? youtubeUsername,
    String? youtubeCustomName,
    CreatorImportMode importMode = CreatorImportMode.recent30,
    CreatorSortOrder sortOrder = CreatorSortOrder.newest,
    bool autoSyncEnabled = false,
  }) async {
    if (autoSyncEnabled && !isPremium) {
      throw const AutoSyncNotAllowedException();
    }
    if (autoSyncEnabled && isPremium) {
      final sources = await _loadSources();
      final syncing = sources
          .where(
            (s) =>
                s.sourceType == ContentSourceType.creator && s.autoSyncEnabled,
          )
          .length;
      if (syncing >= PlanLimits.premiumMaxAutoSyncCreators) {
        throw const AutoSyncNotAllowedException();
      }
    }

    final label = displayName.trim().isNotEmpty
        ? displayName.trim()
        : youtubeHandle != null
        ? '@$youtubeHandle'
        : youtubeChannelId ??
              youtubeUsername ??
              youtubeCustomName ??
              'YouTube creator';

    final now = DateTime.now();
    final source = ContentSource(
      id: 'src_${now.microsecondsSinceEpoch}_${_random.nextInt(9999)}',
      tupicChannelId: tupicChannelId,
      sourceType: ContentSourceType.creator,
      originalUrl: originalUrl,
      youtubeChannelId: youtubeChannelId,
      youtubeHandle: youtubeHandle,
      youtubeUsername: youtubeUsername,
      youtubeCustomName: youtubeCustomName,
      displayName: label,
      createdAt: now,
      updatedAt: now,
      importStatus: ImportStatus.pendingFetch,
      creatorImportMode: importMode,
      creatorSortOrder: sortOrder,
      autoSyncEnabled: autoSyncEnabled,
    );
    final sources = await _loadSources();
    await _saveSources([...sources, source]);
    return source;
  }

  @override
  Future<ContentSource> updateCreatorOptions({
    required String sourceId,
    CreatorImportMode? importMode,
    CreatorSortOrder? sortOrder,
    bool? autoSyncEnabled,
  }) async {
    final sources = await _loadSources();
    final index = sources.indexWhere((s) => s.id == sourceId);
    if (index < 0) throw ContentSourceNotFoundException(sourceId);
    final current = sources[index];
    if (current.sourceType != ContentSourceType.creator) {
      throw ContentSourceNotFoundException(sourceId);
    }

    final enableSync = autoSyncEnabled ?? current.autoSyncEnabled;
    if (enableSync && !isPremium) {
      throw const AutoSyncNotAllowedException();
    }

    final updated = current.copyWith(
      creatorImportMode: importMode,
      creatorSortOrder: sortOrder,
      autoSyncEnabled: autoSyncEnabled,
      updatedAt: DateTime.now(),
    );
    final next = [...sources];
    next[index] = updated;
    await _saveSources(next);
    return updated;
  }

  @override
  Future<void> reorderVideos({
    required String tupicChannelId,
    required List<String> youtubeVideoIdsInOrder,
  }) async {
    final videos = await _loadVideos();
    final next = <ChannelVideo>[];
    for (final video in videos) {
      if (video.tupicChannelId != tupicChannelId) {
        next.add(video);
        continue;
      }
      final order = youtubeVideoIdsInOrder.indexOf(video.youtubeVideoId);
      next.add(video.copyWith(manualOrder: order < 0 ? video.manualOrder : order));
    }
    await _saveVideos(next);
  }

  @override
  Future<ChannelVideo> setVideoExcluded({
    required String tupicChannelId,
    required String youtubeVideoId,
    required bool excluded,
  }) async {
    final videos = await _loadVideos();
    final index = videos.indexWhere(
      (v) =>
          v.tupicChannelId == tupicChannelId &&
          v.youtubeVideoId == youtubeVideoId,
    );
    if (index < 0) {
      throw ContentSourceNotFoundException(youtubeVideoId);
    }
    final updated = videos[index].copyWith(isExcluded: excluded);
    final next = [...videos];
    next[index] = updated;
    await _saveVideos(next);
    return updated;
  }

  @override
  Future<void> deleteVideo({
    required String tupicChannelId,
    required String youtubeVideoId,
  }) async {
    final videos = await _loadVideos();
    final target = videos.where(
      (v) =>
          v.tupicChannelId == tupicChannelId &&
          v.youtubeVideoId == youtubeVideoId,
    );
    if (target.isEmpty) return;

    final sourceIds = target.expand((v) => v.sourceIds).toSet();
    final nextVideos = videos
        .where(
          (v) =>
              !(v.tupicChannelId == tupicChannelId &&
                  v.youtubeVideoId == youtubeVideoId),
        )
        .toList();
    await _saveVideos(nextVideos);

    // Remove orphaned individual-video sources that only pointed at this video.
    final sources = await _loadSources();
    final nextSources = sources.where((source) {
      if (!sourceIds.contains(source.id)) return true;
      if (source.sourceType != ContentSourceType.video) return true;
      return false;
    }).toList();
    await _saveSources(nextSources);
  }

  @override
  Future<SourceDeleteImpact> deleteSource(String sourceId) async {
    final sources = await _loadSources();
    final index = sources.indexWhere((s) => s.id == sourceId);
    if (index < 0) throw ContentSourceNotFoundException(sourceId);
    final source = sources[index];

    final videos = await _loadVideos();
    var removed = 0;
    var retained = 0;
    final nextVideos = <ChannelVideo>[];
    for (final video in videos) {
      if (!video.sourceIds.contains(sourceId)) {
        nextVideos.add(video);
        continue;
      }
      final remaining = video.sourceIds.where((id) => id != sourceId).toList();
      if (remaining.isEmpty) {
        removed++;
        // drop video
      } else {
        retained++;
        nextVideos.add(video.copyWith(sourceIds: remaining));
      }
    }

    final nextSources = [...sources]..removeAt(index);
    await _saveSources(nextSources);
    await _saveVideos(nextVideos);
    return SourceDeleteImpact(
      source: source,
      removedVideoCount: removed,
      retainedVideoCount: retained,
    );
  }

  @override
  Future<void> deleteAllForChannel(String tupicChannelId) async {
    final sources = await _loadSources();
    final videos = await _loadVideos();
    await _saveSources(
      sources.where((s) => s.tupicChannelId != tupicChannelId).toList(),
    );
    await _saveVideos(
      videos.where((v) => v.tupicChannelId != tupicChannelId).toList(),
    );
  }

  @override
  Future<ContentSource> updateSourceImportState({
    required String sourceId,
    required ImportStatus importStatus,
    DateTime? lastFetchedAt,
    int? fetchedVideoCount,
    String? lastErrorMessage,
    bool clearLastError = false,
  }) async {
    final sources = await _loadSources();
    final index = sources.indexWhere((s) => s.id == sourceId);
    if (index < 0) throw ContentSourceNotFoundException(sourceId);
    final updated = sources[index].copyWith(
      importStatus: importStatus,
      lastFetchedAt: lastFetchedAt,
      fetchedVideoCount: fetchedVideoCount,
      lastErrorMessage: lastErrorMessage,
      clearLastError: clearLastError,
      updatedAt: DateTime.now(),
    );
    final next = [...sources];
    next[index] = updated;
    await _saveSources(next);
    return updated;
  }

  @override
  Future<PlaylistImportReport> importPlaylistVideos({
    required String sourceId,
    required List<PlaylistVideoItem> items,
    required bool truncatedByLimit,
    required bool hasMoreOnYoutube,
    required int skippedInvalidCount,
    int excludedPrivateDeleted = 0,
    int excludedNotEmbeddable = 0,
    int excludedMissing = 0,
    Set<String> unplayableVideoIds = const {},
  }) async {
    final sources = await _loadSources();
    final sourceIndex = sources.indexWhere((s) => s.id == sourceId);
    if (sourceIndex < 0) throw ContentSourceNotFoundException(sourceId);
    final source = sources[sourceIndex];
    if (source.sourceType != ContentSourceType.playlist) {
      throw ContentSourceNotFoundException(sourceId);
    }

    final videos = await _loadVideos();
    final now = DateTime.now();
    final nextVideos = <ChannelVideo>[];
    var prunedUnplayableCount = 0;

    // Prune unplayable / placeholder rows linked to this source first so the
    // free 100 limit is recalculated against playable videos only.
    for (final video in videos) {
      final linkedHere = video.sourceIds.contains(sourceId);
      final shouldPrune = linkedHere &&
          (unplayableVideoIds.contains(video.youtubeVideoId) ||
              isPlaceholderVideoTitle(video.title));
      if (!shouldPrune) {
        nextVideos.add(video);
        continue;
      }
      prunedUnplayableCount++;
      final remaining =
          video.sourceIds.where((id) => id != sourceId).toList(growable: false);
      if (remaining.isEmpty) {
        // Orphaned — drop from store. Other sources keep their own videos.
        continue;
      }
      nextVideos.add(video.copyWith(sourceIds: remaining));
    }

    final channelVideos = nextVideos
        .where((v) => v.tupicChannelId == source.tupicChannelId)
        .toList();
    final byId = {
      for (final video in channelVideos) video.youtubeVideoId: video,
    };

    var activeCount = channelVideos.where((v) => !v.isExcluded).length;
    var nextOrder = channelVideos.isEmpty
        ? 0
        : channelVideos
                  .map((v) => v.manualOrder)
                  .reduce((a, b) => a > b ? a : b) +
              1;

    var imported = 0;
    var duplicates = 0;
    var omittedByLimit = 0;

    // Preserve playlist order among newly accepted items.
    final ordered = [...items]..sort((a, b) => a.position.compareTo(b.position));

    for (final item in ordered) {
      if (isPlaceholderVideoTitle(item.title) ||
          unplayableVideoIds.contains(item.youtubeVideoId)) {
        continue;
      }

      final existing = byId[item.youtubeVideoId];
      if (existing != null) {
        duplicates++;
        if (!existing.sourceIds.contains(sourceId)) {
          final idx = nextVideos.indexWhere(
            (v) =>
                v.tupicChannelId == source.tupicChannelId &&
                v.youtubeVideoId == item.youtubeVideoId,
          );
          if (idx >= 0) {
            final linked = nextVideos[idx].copyWith(
              sourceIds: [...nextVideos[idx].sourceIds, sourceId],
              title: item.title,
              thumbnailUrl: item.thumbnailUrl ?? nextVideos[idx].thumbnailUrl,
              metadataStatus: MetadataStatus.resolved,
            );
            nextVideos[idx] = linked;
            byId[item.youtubeVideoId] = linked;
          }
        }
        continue;
      }

      if (activeCount >= maxVideosPerChannel) {
        omittedByLimit++;
        continue;
      }

      final video = ChannelVideo(
        youtubeVideoId: item.youtubeVideoId,
        tupicChannelId: source.tupicChannelId,
        sourceIds: [sourceId],
        title: item.title,
        thumbnailUrl:
            item.thumbnailUrl ??
            ChannelVideo.defaultThumbnailUrl(item.youtubeVideoId),
        metadataStatus: MetadataStatus.resolved,
        addedAt: now,
        manualOrder: nextOrder++,
      );
      nextVideos.add(video);
      byId[item.youtubeVideoId] = video;
      imported++;
      activeCount++;
    }

    final linkedCount = nextVideos
        .where(
          (v) =>
              v.tupicChannelId == source.tupicChannelId &&
              v.sourceIds.contains(sourceId),
        )
        .length;

    final hitLimit = truncatedByLimit || omittedByLimit > 0 || hasMoreOnYoutube;
    final status = linkedCount == 0 && imported == 0 && duplicates == 0
        ? ImportStatus.fetched
        : hitLimit
        ? ImportStatus.partiallyFetched
        : ImportStatus.fetched;

    final updatedSource = source.copyWith(
      importStatus: status,
      lastFetchedAt: now,
      fetchedVideoCount: linkedCount,
      clearLastError: true,
      updatedAt: now,
    );
    final nextSources = [...sources];
    nextSources[sourceIndex] = updatedSource;

    await _saveVideos(nextVideos);
    await _saveSources(nextSources);

    return PlaylistImportReport(
      sourceId: sourceId,
      importedCount: imported,
      duplicateCount: duplicates,
      skippedInvalidCount: skippedInvalidCount,
      omittedByLimitCount: omittedByLimit,
      truncatedByLimit: hitLimit,
      hasMoreOnYoutube: hasMoreOnYoutube,
      totalLinkedToSource: linkedCount,
      excludedPrivateDeleted: excludedPrivateDeleted,
      excludedNotEmbeddable: excludedNotEmbeddable,
      excludedMissing: excludedMissing,
      prunedUnplayableCount: prunedUnplayableCount,
    );
  }

  Future<List<ContentSource>> _loadSources() async {
    final prefs = await _prefs();
    final raw = prefs.getString(sourcesKey);
    if (raw == null || raw.isEmpty) {
      _sourcesCorrupt = false;
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _sourcesCorrupt = true;
        return const [];
      }
      final items = <ContentSource>[];
      for (final item in decoded) {
        final map = _asStringKeyedMap(item);
        final source = ContentSource.fromJson(map);
        if (source != null) items.add(source);
      }
      _sourcesCorrupt = false;
      return items;
    } catch (_) {
      _sourcesCorrupt = true;
      return const [];
    }
  }

  Future<List<ChannelVideo>> _loadVideos() async {
    final prefs = await _prefs();
    final raw = prefs.getString(videosKey);
    if (raw == null || raw.isEmpty) {
      _videosCorrupt = false;
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _videosCorrupt = true;
        return const [];
      }
      final items = <ChannelVideo>[];
      for (final item in decoded) {
        final map = _asStringKeyedMap(item);
        final video = ChannelVideo.fromJson(map);
        if (video != null) items.add(video);
      }
      _videosCorrupt = false;
      return items;
    } catch (_) {
      _videosCorrupt = true;
      return const [];
    }
  }

  Future<void> _saveSources(List<ContentSource> sources) async {
    if (_sourcesCorrupt) {
      throw StateError('Refusing to overwrite corrupt sources store');
    }
    final prefs = await _prefs();
    final payload = jsonEncode(sources.map((s) => s.toJson()).toList());
    final previous = prefs.getString(sourcesKey);
    if (previous != null) {
      await prefs.setString(sourcesBackupKey, previous);
    }
    await prefs.setString(sourcesKey, payload);
  }

  Future<void> _saveVideos(List<ChannelVideo> videos) async {
    if (_videosCorrupt) {
      throw StateError('Refusing to overwrite corrupt videos store');
    }
    final prefs = await _prefs();
    final payload = jsonEncode(videos.map((v) => v.toJson()).toList());
    final previous = prefs.getString(videosKey);
    if (previous != null) {
      await prefs.setString(videosBackupKey, previous);
    }
    await prefs.setString(videosKey, payload);
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic item) {
    if (item is Map<String, dynamic>) return item;
    if (item is Map) {
      return item.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}
