/// Identifiers and versions for legal documents shown in-app.
///
/// Bump [version] when the corresponding document text changes so consent
/// records stay tied to the text the user actually accepted.
class LegalDocumentIds {
  LegalDocumentIds._();

  static const termsOfService = 'terms_of_service';
  static const privacyPolicy = 'privacy_policy';

  /// Optional future item when account-linked personal data is collected
  /// (e.g. Google sign-in). Not required for local-only use today.
  static const privacyCollectionConsent = 'privacy_collection_consent';
}

class LegalDocumentVersions {
  LegalDocumentVersions._();

  static const termsOfService = '2026-11-06';
  static const privacyPolicy = '2026-11-06';
  static const privacyCollectionConsent = '2026-11-06';
}

enum LegalDocumentKind {
  termsOfService,
  privacyPolicy,
}

extension LegalDocumentKindX on LegalDocumentKind {
  String get id => switch (this) {
        LegalDocumentKind.termsOfService => LegalDocumentIds.termsOfService,
        LegalDocumentKind.privacyPolicy => LegalDocumentIds.privacyPolicy,
      };

  String get version => switch (this) {
        LegalDocumentKind.termsOfService =>
          LegalDocumentVersions.termsOfService,
        LegalDocumentKind.privacyPolicy => LegalDocumentVersions.privacyPolicy,
      };
}
