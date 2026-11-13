enum PlayOrder {
  /// Title A→Z / 가나다 (natural).
  titleAsc,

  /// Title Z→A / 역가나다 (natural).
  titleDesc,

  /// Most recently added to the TUPICK channel first.
  newestAdded,

  /// Earliest added to the TUPICK channel first.
  oldestAdded,

  /// Fresh random order each time a queue is built.
  shuffle,
}

extension PlayOrderX on PlayOrder {
  String get storageValue => name;

  /// Maps persisted values. Legacy `sequential` (manual/add order) → [oldestAdded].
  static PlayOrder fromStorage(String? value) {
    return switch (value) {
      'titleAsc' => PlayOrder.titleAsc,
      'titleDesc' => PlayOrder.titleDesc,
      'newestAdded' => PlayOrder.newestAdded,
      'oldestAdded' => PlayOrder.oldestAdded,
      'shuffle' => PlayOrder.shuffle,
      // Pre-STEP-6A: sequential ≈ registration / manualOrder ascending.
      'sequential' => PlayOrder.oldestAdded,
      _ => PlayOrder.oldestAdded,
    };
  }
}
