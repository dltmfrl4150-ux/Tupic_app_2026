import 'package:flutter/material.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/legal_documents.dart';
import '../domain/legal_document.dart';

class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({super.key, required this.kind});

  final LegalDocumentKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final doc = legalDocumentContent(kind, locale: locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.title),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            l10n.legalVersionLabel(doc.version),
            style: const TextStyle(
              color: TupicColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.legalDraftNotice,
            style: const TextStyle(
              color: TupicColors.mutedText,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TupicColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TupicColors.borderSubtle),
            ),
            child: SelectableText(
              doc.body,
              style: const TextStyle(
                color: TupicColors.primaryText,
                height: 1.55,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> openLegalDocument(
  BuildContext context,
  LegalDocumentKind kind,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => LegalDocumentPage(kind: kind),
    ),
  );
}
