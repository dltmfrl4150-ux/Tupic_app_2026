import 'package:flutter/material.dart';

import '../../app/theme/tupic_colors.dart';
import '../../l10n/app_localizations.dart';
import 'space_motif_painter.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.loading,
            style: const TextStyle(color: TupicColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: TupicColors.mutedText),
            const SizedBox(height: 12),
            Text(
              l10n.errorTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: TupicColors.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: Text(l10n.errorRetry)),
          ],
        ),
      ),
    );
  }
}

class EmptySection extends StatelessWidget {
  const EmptySection({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.inbox_outlined,
    this.showSpaceMotif = true,
  });

  final String title;
  final String body;
  final IconData icon;
  final bool showSpaceMotif;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: TupicColors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TupicColors.borderSubtle),
      ),
      child: Column(
        children: [
          if (showSpaceMotif)
            SizedBox(
              width: 72,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      TupicColors.selected.withValues(alpha: 0.9),
                      TupicColors.secondary,
                    ],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: const CustomPaint(
                    painter: SpaceMotifPainter(seed: 21, dense: true),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            )
          else
            Icon(icon, size: 36, color: TupicColors.mutedText),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: TupicColors.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: TupicColors.mutedText, height: 1.4),
          ),
        ],
      ),
    );
  }
}
