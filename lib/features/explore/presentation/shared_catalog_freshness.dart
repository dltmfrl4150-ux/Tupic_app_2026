import 'package:flutter/foundation.dart';

/// Signals that published explore/home catalog data may be stale.
///
/// Bumped only after successful share publish/cancel — not on every UI notify.
class SharedCatalogFreshness extends ChangeNotifier {
  int _generation = 0;

  int get generation => _generation;

  /// Marks explore/home listings dirty so mounted listeners re-fetch once.
  void markDirty() {
    _generation++;
    notifyListeners();
  }
}
