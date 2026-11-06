import '../domain/legal_document.dart';
import 'privacy_policy_ko.dart';
import 'terms_of_service_ko.dart';

class LegalDocumentContent {
  const LegalDocumentContent({
    required this.kind,
    required this.title,
    required this.body,
    required this.version,
  });

  final LegalDocumentKind kind;
  final String title;
  final String body;
  final String version;
}

LegalDocumentContent legalDocumentContent(LegalDocumentKind kind) {
  return switch (kind) {
    LegalDocumentKind.termsOfService => const LegalDocumentContent(
        kind: LegalDocumentKind.termsOfService,
        title: TermsOfServiceKo.title,
        body: TermsOfServiceKo.body,
        version: TermsOfServiceKo.version,
      ),
    LegalDocumentKind.privacyPolicy => const LegalDocumentContent(
        kind: LegalDocumentKind.privacyPolicy,
        title: PrivacyPolicyKo.title,
        body: PrivacyPolicyKo.body,
        version: PrivacyPolicyKo.version,
      ),
  };
}
