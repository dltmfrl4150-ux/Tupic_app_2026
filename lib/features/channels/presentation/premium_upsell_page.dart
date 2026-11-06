import 'package:flutter/material.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../core/constants/plan_limits.dart';
import '../../../l10n/app_localizations.dart';

class PremiumUpsellPage extends StatelessWidget {
  const PremiumUpsellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.premiumTitle),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TupicColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TupicColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.premiumLimitTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: TupicColors.primaryText,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.premiumLimitBody(PlanLimits.freeMaxChannels),
                  style: const TextStyle(
                    color: TupicColors.mutedText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.premiumBody,
                  style: const TextStyle(
                    color: TupicColors.mutedText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.premiumBillingDisabled,
                  style: const TextStyle(
                    color: TupicColors.accentViolet,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(l10n.comingSoonOk),
          ),
        ],
      ),
    );
  }
}
