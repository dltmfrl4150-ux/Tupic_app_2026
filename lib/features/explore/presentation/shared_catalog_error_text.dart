import '../../../l10n/app_localizations.dart';
import '../../../shared/repositories/shared_channel_catalog_repository.dart';

/// User-facing copy for catalog load failures (not all are "network").
({String title, String body}) sharedCatalogErrorText(
  AppLocalizations l10n,
  SharedCatalogFailureCode? code,
) {
  return switch (code) {
    SharedCatalogFailureCode.indexRequired => (
        title: l10n.exploreLoadFailedIndexTitle,
        body: l10n.exploreLoadFailedIndexBody,
      ),
    SharedCatalogFailureCode.permissionDenied => (
        title: l10n.exploreLoadFailedPermissionTitle,
        body: l10n.exploreLoadFailedPermissionBody,
      ),
    SharedCatalogFailureCode.network => (
        title: l10n.exploreLoadFailedTitle,
        body: l10n.exploreLoadFailedBody,
      ),
    SharedCatalogFailureCode.unknown || null => (
        title: l10n.exploreLoadFailedTitle,
        body: l10n.exploreLoadFailedUnknownBody,
      ),
  };
}

SharedCatalogFailureCode? sharedCatalogFailureCodeOf(Object error) {
  if (error is SharedCatalogException) return error.code;
  return null;
}
