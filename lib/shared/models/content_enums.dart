enum ContentSourceType {
  video,
  playlist,
  creator,
}

enum ImportStatus {
  /// Individual video ready for local use (no API needed).
  ready,

  /// Playlist/creator registered; video fetch waits for API.
  pendingFetch,

  /// Fetch in progress (UI only; may not persist across restarts).
  fetching,

  /// All requested items imported within plan limits.
  fetched,

  /// Imported some items; more remain or free limit stopped import.
  partiallyFetched,

  failed,
}

enum MetadataStatus {
  unresolved,
  resolved,
  failed,
}

enum CreatorImportMode {
  recent30,
  all,
  manual,
}

enum CreatorSortOrder {
  newest,
  oldest,
  shuffle,
}

extension ContentSourceTypeX on ContentSourceType {
  String get storageValue => name;

  static ContentSourceType? fromStorage(String? value) {
    return switch (value) {
      'video' => ContentSourceType.video,
      'playlist' => ContentSourceType.playlist,
      'creator' => ContentSourceType.creator,
      _ => null,
    };
  }
}

extension ImportStatusX on ImportStatus {
  String get storageValue => name;

  static ImportStatus fromStorage(String? value) {
    return switch (value) {
      'pendingFetch' => ImportStatus.pendingFetch,
      'fetching' => ImportStatus.pendingFetch, // transient; resume as pending
      'fetched' => ImportStatus.fetched,
      'partiallyFetched' => ImportStatus.partiallyFetched,
      'failed' => ImportStatus.failed,
      _ => ImportStatus.ready,
    };
  }
}

extension MetadataStatusX on MetadataStatus {
  String get storageValue => name;

  static MetadataStatus fromStorage(String? value) {
    return switch (value) {
      'resolved' => MetadataStatus.resolved,
      'failed' => MetadataStatus.failed,
      _ => MetadataStatus.unresolved,
    };
  }
}

extension CreatorImportModeX on CreatorImportMode {
  String get storageValue => name;

  static CreatorImportMode fromStorage(String? value) {
    return switch (value) {
      'all' => CreatorImportMode.all,
      'manual' => CreatorImportMode.manual,
      _ => CreatorImportMode.recent30,
    };
  }
}

extension CreatorSortOrderX on CreatorSortOrder {
  String get storageValue => name;

  static CreatorSortOrder fromStorage(String? value) {
    return switch (value) {
      'oldest' => CreatorSortOrder.oldest,
      'shuffle' => CreatorSortOrder.shuffle,
      _ => CreatorSortOrder.newest,
    };
  }
}
