import 'package:flutter/widgets.dart';

import '../../../shared/repositories/shared_channel_catalog_repository.dart';
import 'shared_catalog_freshness.dart';

class SharedCatalogScope extends InheritedWidget {
  const SharedCatalogScope({
    super.key,
    required this.catalog,
    required this.freshness,
    required super.child,
  });

  final SharedChannelCatalogRepository catalog;
  final SharedCatalogFreshness freshness;

  static SharedCatalogScope _scope(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<SharedCatalogScope>();
    assert(scope != null, 'SharedCatalogScope not found');
    return scope!;
  }

  static SharedChannelCatalogRepository of(BuildContext context) =>
      _scope(context).catalog;

  static SharedChannelCatalogRepository? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SharedCatalogScope>()
        ?.catalog;
  }

  static SharedCatalogFreshness freshnessOf(BuildContext context) =>
      _scope(context).freshness;

  static SharedCatalogFreshness? maybeFreshnessOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SharedCatalogScope>()
        ?.freshness;
  }

  @override
  bool updateShouldNotify(SharedCatalogScope oldWidget) =>
      catalog != oldWidget.catalog || freshness != oldWidget.freshness;
}
