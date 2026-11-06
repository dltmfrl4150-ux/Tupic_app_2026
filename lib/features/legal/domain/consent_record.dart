import 'legal_document.dart';

/// Minimal local consent record. Not equivalent to a server-verified audit log.
class ConsentRecord {
  const ConsentRecord({
    required this.itemId,
    required this.documentVersion,
    required this.acceptedAt,
  });

  final String itemId;
  final String documentVersion;
  final DateTime acceptedAt;

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'documentVersion': documentVersion,
      'acceptedAt': acceptedAt.toIso8601String(),
    };
  }

  static ConsentRecord? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final itemId = json['itemId'];
    final version = json['documentVersion'];
    final acceptedRaw = json['acceptedAt'];
    if (itemId is! String || version is! String || acceptedRaw is! String) {
      return null;
    }
    final acceptedAt = DateTime.tryParse(acceptedRaw);
    if (acceptedAt == null) return null;
    return ConsentRecord(
      itemId: itemId,
      documentVersion: version,
      acceptedAt: acceptedAt,
    );
  }
}

/// One checkbox row on the consent panel.
class ConsentItemSpec {
  const ConsentItemSpec({
    required this.itemId,
    required this.documentVersion,
    required this.label,
    required this.required,
    this.viewDocument,
  });

  final String itemId;
  final String documentVersion;
  final String label;
  final bool required;

  /// Optional document opened by the row's "보기" action.
  final LegalDocumentKind? viewDocument;
}

/// Specs used when Google sign-in (STEP 5C) asks for local consents.
///
/// Today only terms acceptance is required. A separate personal-information
/// collection consent is omitted until the app actually collects account data
/// that needs that legal basis — avoiding blanket forced consent.
List<ConsentItemSpec> defaultLocalConsentItems({
  required String termsLabel,
}) {
  return [
    ConsentItemSpec(
      itemId: LegalDocumentIds.termsOfService,
      documentVersion: LegalDocumentVersions.termsOfService,
      label: termsLabel,
      required: true,
      viewDocument: LegalDocumentKind.termsOfService,
    ),
  ];
}
