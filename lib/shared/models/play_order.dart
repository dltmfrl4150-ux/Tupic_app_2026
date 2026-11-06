enum PlayOrder {
  sequential,
  shuffle,
}

extension PlayOrderX on PlayOrder {
  String get storageValue => name;

  static PlayOrder fromStorage(String? value) {
    return switch (value) {
      'shuffle' => PlayOrder.shuffle,
      _ => PlayOrder.sequential,
    };
  }
}
