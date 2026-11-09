import 'dart:ui' show Locale;

import '../domain/legal_document.dart';
import 'privacy_policy_en.dart';
import 'privacy_policy_ko.dart';
import 'terms_of_service_en.dart';
import 'terms_of_service_ko.dart';

class LegalDocumentContent {
  const LegalDocumentContent({
    required this.kind,
    required this.title,
    required this.body,
    required this.version,
    required this.languageCode,
  });

  final LegalDocumentKind kind;
  final String title;
  final String body;
  final String version;

  /// Resolved document language (`ko` or `en`).
  final String languageCode;
}

/// Matches MaterialApp fallback: Korean docs for `ko`, otherwise English.
String resolveLegalLanguageCode(Locale? locale) {
  final code = locale?.languageCode.toLowerCase();
  if (code == 'ko') return 'ko';
  return 'en';
}

/// Shared selector for consent "View" and Settings legal links.
LegalDocumentContent legalDocumentContent(
  LegalDocumentKind kind, {
  Locale? locale,
}) {
  final language = resolveLegalLanguageCode(locale);
  return switch ((kind, language)) {
    (LegalDocumentKind.termsOfService, 'ko') => const LegalDocumentContent(
        kind: LegalDocumentKind.termsOfService,
        title: TermsOfServiceKo.title,
        body: TermsOfServiceKo.body,
        version: TermsOfServiceKo.version,
        languageCode: 'ko',
      ),
    (LegalDocumentKind.termsOfService, _) => const LegalDocumentContent(
        kind: LegalDocumentKind.termsOfService,
        title: TermsOfServiceEn.title,
        body: TermsOfServiceEn.body,
        version: TermsOfServiceEn.version,
        languageCode: 'en',
      ),
    (LegalDocumentKind.privacyPolicy, 'ko') => const LegalDocumentContent(
        kind: LegalDocumentKind.privacyPolicy,
        title: PrivacyPolicyKo.title,
        body: PrivacyPolicyKo.body,
        version: PrivacyPolicyKo.version,
        languageCode: 'ko',
      ),
    (LegalDocumentKind.privacyPolicy, _) => const LegalDocumentContent(
        kind: LegalDocumentKind.privacyPolicy,
        title: PrivacyPolicyEn.title,
        body: PrivacyPolicyEn.body,
        version: PrivacyPolicyEn.version,
        languageCode: 'en',
      ),
  };
}
