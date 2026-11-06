import 'package:flutter/material.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/local_consent_repository.dart';
import '../domain/consent_record.dart';
import '../domain/legal_document.dart';
import 'legal_document_page.dart';

/// Reusable consent UI for future Google sign-in (STEP 5C).
///
/// Does not auto-show on app launch. Records consent only when the user taps
/// continue with required boxes checked — never on document view alone.
class ConsentPanel extends StatefulWidget {
  const ConsentPanel({
    super.key,
    required this.items,
    required this.onAccepted,
    this.repository,
    this.title,
    this.subtitle,
    this.showPrivacyPolicyLink = true,
    this.continueLabel,
  });

  final List<ConsentItemSpec> items;
  final Future<void> Function(List<ConsentRecord> records) onAccepted;
  final LocalConsentRepository? repository;
  final String? title;
  final String? subtitle;
  final bool showPrivacyPolicyLink;
  final String? continueLabel;

  @override
  State<ConsentPanel> createState() => _ConsentPanelState();
}

class _ConsentPanelState extends State<ConsentPanel> {
  late final Map<String, bool> _checked;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _checked = {
      for (final item in widget.items) item.itemId: false,
    };
  }

  bool get _allRequiredChecked {
    for (final item in widget.items) {
      if (item.required && _checked[item.itemId] != true) {
        return false;
      }
    }
    return widget.items.isNotEmpty;
  }

  Future<void> _onContinue() async {
    if (!_allRequiredChecked || _submitting) return;
    setState(() => _submitting = true);
    final now = DateTime.now().toUtc();
    final records = <ConsentRecord>[
      for (final item in widget.items)
        if (_checked[item.itemId] == true)
          ConsentRecord(
            itemId: item.itemId,
            documentVersion: item.documentVersion,
            acceptedAt: now,
          ),
    ];

    try {
      final repo = widget.repository ?? LocalConsentRepository();
      await repo.recordConsents(records);
      await widget.onAccepted(records);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = widget.title ?? l10n.consentTitle;
    final subtitle = widget.subtitle ?? l10n.consentSubtitle;
    final continueLabel = widget.continueLabel ?? l10n.consentContinue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TupicColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TupicColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: TupicColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: TupicColors.mutedText,
              height: 1.4,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    key: Key('consent_check_${item.itemId}'),
                    value: _checked[item.itemId] ?? false,
                    activeColor: TupicColors.accentViolet,
                    onChanged: (value) {
                      setState(() {
                        _checked[item.itemId] = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: TupicColors.primaryText,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                  if (item.viewDocument != null)
                    TextButton(
                      key: Key('consent_view_${item.itemId}'),
                      onPressed: () =>
                          openLegalDocument(context, item.viewDocument!),
                      child: Text(l10n.legalView),
                    ),
                ],
              ),
            );
          }),
          if (widget.showPrivacyPolicyLink) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('consent_privacy_policy_link'),
                onPressed: () => openLegalDocument(
                  context,
                  LegalDocumentKind.privacyPolicy,
                ),
                icon: const Icon(Icons.policy_outlined, size: 18),
                label: Text(l10n.privacyPolicyViewAlways),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            key: const Key('consent_continue_button'),
            onPressed: _allRequiredChecked && !_submitting ? _onContinue : null,
            child: Text(continueLabel),
          ),
        ],
      ),
    );
  }
}

/// Full-screen host for [ConsentPanel]. Intended for STEP 5C sign-in gate.
class ConsentPage extends StatelessWidget {
  const ConsentPage({
    super.key,
    required this.items,
    required this.onAccepted,
    this.repository,
  });

  final List<ConsentItemSpec> items;
  final Future<void> Function(List<ConsentRecord> records) onAccepted;
  final LocalConsentRepository? repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            ConsentPanel(
              items: items,
              repository: repository,
              onAccepted: onAccepted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Interface for STEP 5C: show consent only when current terms are missing.
class ConsentFlow {
  ConsentFlow({LocalConsentRepository? repository})
      : _repository = repository ?? LocalConsentRepository();

  final LocalConsentRepository _repository;

  LocalConsentRepository get repository => _repository;

  Future<bool> needsTermsConsent() async {
    return !(await _repository.hasAcceptedCurrentTerms());
  }

  /// Pushes consent UI if needed. Returns false if user pops without accepting.
  /// Does not call itself from app startup — caller (login) decides when.
  Future<bool> ensureTermsConsent(BuildContext context) async {
    if (!await needsTermsConsent()) return true;
    if (!context.mounted) return false;

    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final accepted = await navigator.push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (pageContext) => ConsentPage(
          repository: _repository,
          items: defaultLocalConsentItems(
            termsLabel: l10n.consentTermsRequired,
          ),
          onAccepted: (records) async {
            Navigator.of(pageContext).pop(records.isNotEmpty);
          },
        ),
      ),
    );
    return accepted == true;
  }
}
