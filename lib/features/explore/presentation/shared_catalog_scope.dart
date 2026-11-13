import 'package:flutter/widgets.dart';

import '../../../shared/repositories/shared_channel_catalog_repository.dart';

class SharedCatalogScope extends InheritedWidget {
  const SharedCatalogScope({
    super.key,
    required this.catalog,
    required super.child,
  });

  final SharedChannelCatalogRepository catalog;

  static SharedChannelCatalogRepository of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<SharedCatalogScope>();
    assert(scope != null, 'SharedCatalogScope not found');
    return scope!.catalog;
  }

  static SharedChannelCatalogRepository? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SharedCatalogScope>()
        ?.catalog;
  }

  @override
  bool updateShouldNotify(SharedCatalogScope oldWidget) =>
      catalog != oldWidget.catalog;
}
