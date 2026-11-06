import 'package:flutter/material.dart';

import '../../../app/locale_controller.dart';
import '../../../app/theme/tupic_colors.dart';
import '../../../core/utils/locale_preference.dart';
import '../../../l10n/app_localizations.dart';
import '../../legal/domain/legal_document.dart';
import '../../legal/presentation/legal_document_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeController = LocaleScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            l10n.settingsLanguage,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: TupicColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          RadioGroup<AppLocalePreference>(
            groupValue: localeController.preference,
            onChanged: (value) {
              if (value != null) {
                localeController.setPreference(value);
              }
            },
            child: Column(
              children: AppLocalePreference.values.map((preference) {
                final label = switch (preference) {
                  AppLocalePreference.system => l10n.languageSystem,
                  AppLocalePreference.korean => l10n.languageKorean,
                  AppLocalePreference.english => l10n.languageEnglish,
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: TupicColors.card,
                    borderRadius: BorderRadius.circular(14),
                    child: RadioListTile<AppLocalePreference>(
                      value: preference,
                      title: Text(label),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: TupicColors.borderSubtle),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.settingsLegalSection,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: TupicColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          _LegalLinkTile(
            key: const Key('settings_terms_link'),
            icon: Icons.description_outlined,
            label: l10n.termsOfServiceTitle,
            onTap: () => openLegalDocument(
              context,
              LegalDocumentKind.termsOfService,
            ),
          ),
          const SizedBox(height: 8),
          _LegalLinkTile(
            key: const Key('settings_privacy_link'),
            icon: Icons.privacy_tip_outlined,
            label: l10n.privacyPolicyTitle,
            onTap: () => openLegalDocument(
              context,
              LegalDocumentKind.privacyPolicy,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.premiumTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: TupicColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.premiumBody,
            style: const TextStyle(color: TupicColors.mutedText, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _LegalLinkTile extends StatelessWidget {
  const _LegalLinkTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TupicColors.card,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        leading: Icon(icon, color: TupicColors.accentViolet),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right_rounded),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: TupicColors.borderSubtle),
        ),
        onTap: onTap,
      ),
    );
  }
}
